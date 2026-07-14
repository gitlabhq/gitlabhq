# frozen_string_literal: true

require_relative 'reply_key'

module Gitlab
  module EmailHandler
    # Helpers for recognising and normalising custom Service Desk email
    # addresses (e.g. support@acme.com). These mirror the parsing in
    # Gitlab::Email::ServiceDesk::CustomEmail but without any database access -
    # whether an address is actually a registered custom email is confirmed by
    # the Topology Service (see CellRouter).
    module CustomEmail
      VERIFICATION_SUBADDRESS = '+verify'

      # Matches a reply address like "support+<reply_key>@acme.com". The full
      # reply key spans everything between the first "+" and the "@"; we then
      # validate that span against the reply-key format. We capture by position
      # (not a named group) to avoid colliding with the named groups inside
      # FULL_REPLY_KEY_REGEX.
      FULL_REPLY_KEY_ANCHORED = /\A#{ReplyKey::FULL_REPLY_KEY_REGEX}\z/
      REPLY_ADDRESS_REGEX = /\A(?<base>[^+]+)\+(?<full_key>[^@]+)@(?<domain>.+)\z/

      # Loose email shape check. Custom emails are arbitrary addresses, so this
      # only filters out obvious non-addresses before asking the Topology
      # Service.
      EMAIL_REGEX = /\A[^@\s]+@[^@\s]+\.[^@\s]+\z/

      module_function

      # Returns the base custom email address for a candidate recipient, with
      # any "+verify" or "+<reply_key>" sub-addressing removed, or nil if the
      # value doesn't look like an email address.
      #
      #   support@acme.com            -> support@acme.com
      #   support+verify@acme.com     -> support@acme.com
      #   support+<reply_key>@acme.com -> support@acme.com
      def base_address(address)
        value = address.to_s.strip
        return unless EMAIL_REGEX.match?(value)

        match = reply_address_match(value)
        return "#{match[:base]}@#{match[:domain]}" if match

        value.sub(VERIFICATION_SUBADDRESS, '')
      end

      # Extracts the reply key from a custom email reply address, or nil.
      #   support+<reply_key>@acme.com -> <reply_key>
      def reply_key(address)
        reply_address_match(address)&.[](:full_key)
      end

      # Matches a reply address and validates the embedded key against the
      # reply-key format, returning the MatchData or nil. Centralising the
      # match avoids running REPLY_ADDRESS_REGEX twice.
      def reply_address_match(address)
        match = REPLY_ADDRESS_REGEX.match(address.to_s)
        return unless match
        return unless FULL_REPLY_KEY_ANCHORED.match?(match[:full_key])

        match
      end
    end
  end
end
