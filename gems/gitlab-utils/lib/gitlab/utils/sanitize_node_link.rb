# frozen_string_literal: true

module Gitlab
  module Utils
    module SanitizeNodeLink
      UNSAFE_PROTOCOLS  = %w[data javascript vbscript].freeze
      ATTRS_TO_SANITIZE = %w[href src data-src data-canonical-src].freeze

      # sanitize 6.0 requires only a context argument. Do not add any default
      # arguments to this method.
      def sanitize_unsafe_links(env)
        # sanitize calls this with every node, so no need to check child nodes
        remove_unsafe_links(env, sanitize_children: false)
      end

      def remove_unsafe_links(env, remove_invalid_links: true, sanitize_children: true)
        node = env[:node]

        sanitize_node(node: node, remove_invalid_links: remove_invalid_links)

        return unless sanitize_children

        # HTML entities such as <video></video> have scannable attrs in
        #   children elements, which also need to be sanitized.
        #
        node.children.each do |child_node|
          sanitize_node(node: child_node, remove_invalid_links: remove_invalid_links)
        end
      end

      # Remove all invalid scheme characters before checking against the
      # list of unsafe protocols.
      #
      # See https://www.rfc-editor.org/rfc/rfc3986#section-3.1
      #
      def safe_protocol?(scheme)
        return false unless scheme

        scheme = scheme
          .strip
          .downcase
          .gsub(/[^A-Za-z+.-]+/, '')

        UNSAFE_PROTOCOLS.none?(scheme)
      end

      # Matches the canonical Ruby message for invalid UTF-8 byte sequences
      # raised from `String#gsub` (and other regex/string operations) when
      # the input contains bytes that are not valid UTF-8. Ruby raises a
      # plain `ArgumentError` here -- neither Addressable nor stdlib wraps
      # it -- so we match by message to avoid swallowing unrelated
      # `ArgumentError`s.
      INVALID_UTF8_BYTE_SEQUENCE_MESSAGE = 'invalid byte sequence in UTF-8'

      def permit_url?(url, remove_invalid_links: true)
        uri = Addressable::URI.parse(url)
        uri = uri.normalize

        return true unless uri.scheme
        return true if safe_protocol?(uri.scheme)

        false
      # `Addressable::URI#normalize` can raise `Encoding::CompatibilityError`
      # (from `String#strip` in `normalized_host`) or `ArgumentError` (from
      # `String#gsub` inside Ruby's `unicode_normalize`, via Addressable's
      # pure IDNA implementation) when the URL contains an invalid UTF-8 byte
      # sequence. Treat these the same as any other invalid URL.
      rescue Addressable::URI::InvalidURIError,
        Addressable::IDNA::PunycodeBigOutput,
        Encoding::CompatibilityError
        return false if remove_invalid_links

        true
      rescue ArgumentError => e
        # Re-raise unrelated `ArgumentError`s so genuine bugs surface
        # instead of being silently masked.
        raise unless e.message.include?(INVALID_UTF8_BYTE_SEQUENCE_MESSAGE)

        return false if remove_invalid_links

        true
      end

      private

      def sanitize_node(node:, remove_invalid_links: true)
        ATTRS_TO_SANITIZE.each do |attr|
          next unless node.has_attribute?(attr)

          node[attr] = node[attr].strip
          node.remove_attribute(attr) unless permit_url?(node[attr], remove_invalid_links: remove_invalid_links)
        end
      end
    end
  end
end
