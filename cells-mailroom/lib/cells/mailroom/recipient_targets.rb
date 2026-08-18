# frozen_string_literal: true

require 'gitlab/email_handler'

module Cells
  module Mailroom
    # Maps a single mail key candidate (yielded by
    # Gitlab::EmailHandler::MailKey.each_candidate) to the ordered routing
    # Target candidates it can produce. The header scanning and precedence live
    # in the gem; this only derives Targets from one candidate, so the mail_room
    # service and the GitLab application stay consistent on which key an email
    # resolves to.
    #
    # For a candidate it yields, in order:
    #
    #   1. A target parsed offline from the incoming/service_desk wildcard key
    #      (project id, namespace id, or route).
    #   2. A target from a custom email reply address whose partitioned reply key
    #      encodes a namespace id (also offline).
    #   3. A service_desk_custom_email target for the bare address.
    #
    # The caller resolves each target against the Topology Service and uses the
    # first that maps to a cell. Custom email candidates double as the existence
    # check: an address that isn't a claimed custom email simply won't resolve.
    module RecipientTargets
      module_function

      # Ordered, de-duplicated Target candidates derived from a single mail key
      # candidate.
      #
      # @param candidate [Gitlab::EmailHandler::MailKey::Candidate]
      # @return [Array<Gitlab::EmailHandler::Target>]
      def for_candidate(candidate)
        [
          target_from_key(candidate.key),
          target_from_custom_email_reply(candidate.value),
          custom_email_target(candidate.value)
        ].compact.uniq
      end

      # A target parsed offline from the wildcard key
      # (incoming+<key>@host -> project id, namespace id, or route).
      def target_from_key(key)
        return unless key

        ::Gitlab::EmailHandler::Identifier.call(key)&.target
      end

      # A custom email reply (support+<reply_key>@acme.com) whose reply key
      # encodes a namespace id, resolved offline.
      def target_from_custom_email_reply(address)
        reply_key = ::Gitlab::EmailHandler::CustomEmail.reply_key(address)
        return unless reply_key

        ::Gitlab::EmailHandler::Identifier.call(reply_key)&.target
      end

      # The bare custom email address, to be confirmed by the Topology Service.
      def custom_email_target(address)
        custom_email = ::Gitlab::EmailHandler::CustomEmail.base_address(address)
        return unless custom_email

        ::Gitlab::EmailHandler::Target.service_desk_custom_email(custom_email)
      end
    end
  end
end
