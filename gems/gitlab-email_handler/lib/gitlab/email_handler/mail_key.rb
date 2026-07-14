# frozen_string_literal: true

module Gitlab
  module EmailHandler
    # Extracts the mail key from an incoming email's headers.
    #
    # This is the single source of truth for *how* an incoming email is scanned
    # for a mail key: the order in which recipient headers (and the references
    # fallback) are tried, how a wildcard address is parsed into a key, and how a
    # fallback message id is parsed. Both the GitLab application
    # (Gitlab::Email::Receiver) and the standalone mail_room service consume this
    # so they can never disagree on which key an email resolves to.
    #
    # The module is pure and config-free: callers pass the wildcard address and
    # the GitLab host as arguments rather than reading them from any global
    # configuration.
    #
    # Callers own *what* to do with each candidate (the application layers in
    # database-backed Service Desk custom email lookups; the mail_room service
    # maps each candidate to a routing Target), but never the ordering. They pass
    # a block to `each_candidate`; the first non-nil value the block returns wins
    # and iteration stops, mirroring the original short-circuiting behavior.
    module MailKey
      # Recipient sources, in the precedence the GitLab application has always
      # used. `:references` is the message-id fallback and is tried after the
      # primary `:to` header but before the remaining headers. `:received`
      # extracts recipients from the Received headers.
      RECIPIENT_HEADERS = %i[
        delivered_to x_delivered_to envelope_to x_envelope_to received x_original_to x_forwarded_to cc
      ].freeze

      # Extracts the recipient address out of a `Received` header, e.g.
      #   Received: from x by y for <incoming+key@host>; <date>
      RECEIVED_HEADER_REGEX = /for\s+<([^<]+)>/

      WILDCARD_PLACEHOLDER = '%{key}'

      # A single mail key candidate.
      #
      # - source: the header the candidate came from (e.g. :to, :references)
      # - value:  the raw recipient address, or message id for :references
      # - key:    the offline-parsed mail key for this candidate, or nil
      Candidate = Data.define(:source, :value, :key)

      module_function

      # Yields each mail key candidate, in precedence order, to the given block.
      # The first non-nil block result is returned and iteration stops. Returns
      # nil when no candidate is found or the block matches nothing.
      #
      # @param mail [Mail::Message]
      # @param wildcard_address [String, nil] the configured incoming/service
      #   desk address containing the `%{key}` placeholder
      # @param gitlab_host [String, nil] the GitLab host, used to parse the
      #   references message-id fallback
      # @yieldparam candidate [Candidate]
      # @return the first non-nil block result, or nil
      def each_candidate(mail, wildcard_address:, gitlab_host:)
        return unless block_given?

        # 1. The primary To header.
        addresses(mail, :to).each do |address|
          result = yield Candidate.new(source: :to, value: address, key: key_from_address(address, wildcard_address))
          return result if result
        end

        # 2. The references message-id fallback.
        reference_message_ids(mail).each do |mail_id|
          result = yield Candidate.new(
            source: :references,
            value: mail_id,
            key: key_from_fallback_message_id(mail_id, gitlab_host)
          )
          return result if result
        end

        # 3. The remaining recipient headers.
        RECIPIENT_HEADERS.each do |source|
          addresses(mail, source).each do |address|
            result = yield Candidate.new(source: source, value: address,
              key: key_from_address(address, wildcard_address))
            return result if result
          end
        end

        nil
      end

      # Parses a mail key out of a recipient address using the wildcard address.
      #
      #   wildcard "incoming+%{key}@host", address "incoming+abc@host" => "abc"
      #
      # @return [String, nil]
      def key_from_address(address, wildcard_address)
        regex = address_regex(wildcard_address)
        return unless regex

        address.to_s.match(regex)&.[](1)
      end

      # Parses a mail key out of a fallback message id of the form
      # `reply-<key>@<gitlab_host>`.
      #
      # @return [String, nil]
      def key_from_fallback_message_id(mail_id, gitlab_host)
        return unless gitlab_host

        mail_id.to_s[/\Areply-(.+)@#{Regexp.escape(gitlab_host)}\z/, 1]
      end

      # Splits a raw References header value into individual message ids. Handles
      # clients that join references with commas (e.g. Microsoft Exchange, iOS).
      #
      # @return [Array<String>]
      def scan_fallback_references(references)
        # Looks for each <...>
        references.to_s.scan(/(?!<)[^<>]+(?=>)/)
      end

      # The addresses for a recipient source, normalized to strings.
      #
      # `:to` and `:cc` use the Mail::Message readers, which return arrays of
      # individual address strings. Every other header is read as a raw field via
      # `mail[header]`, matching how Gitlab::Email::Receiver has always read them.
      def addresses(mail, source)
        case source
        when :to then Array(mail.to)
        when :cc then Array(mail.cc)
        when :received then received_recipients(mail)
        else
          Array(mail[source]).map { |item| item.is_a?(Mail::Field) ? item.value : item.to_s }
        end
      end

      def received_recipients(mail)
        Array(mail[:received]).filter_map { |header| header.value[RECEIVED_HEADER_REGEX, 1] }
      end

      def reference_message_ids(mail)
        references = mail.references

        case references
        when Array then references
        when String then scan_fallback_references(references)
        else []
        end
      end

      def address_regex(wildcard_address)
        return unless wildcard_address

        escaped = Regexp.escape(wildcard_address).sub(Regexp.escape(WILDCARD_PLACEHOLDER), '(.+)')
        /\A<?#{escaped}>?\z/
      end
    end
  end
end
