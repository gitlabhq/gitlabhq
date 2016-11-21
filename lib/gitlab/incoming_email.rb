module Gitlab
  module IncomingEmail
    WILDCARD_PLACEHOLDER = '%{key}'.freeze

    class << self
      FALLBACK_MESSAGE_ID_REGEX = /\Areply\-(.+)@#{Gitlab.config.gitlab.host}\Z/.freeze

      def enabled?
        config.enabled && config.address
      end

      def supports_wildcard?
        config.address && config.address.include?(WILDCARD_PLACEHOLDER)
      end

      def supports_issue_creation?
        enabled? && supports_wildcard?
      end

      def reply_address(key)
        config.address.gsub(WILDCARD_PLACEHOLDER, key)
      end

      def key_from_address(address)
        regex = address_regex
        return unless regex

        match = address.match(regex)
        return unless match

        match[1]
      end

      def key_from_fallback_message_id(mail_id)
        match = mail_id.match(FALLBACK_MESSAGE_ID_REGEX)
        return unless match

        match[1]
      end

      def config
        Gitlab.config.incoming_email
      end

      private

      def address_regex
        wildcard_address = config.address
        return nil unless wildcard_address

        regex = Regexp.escape(wildcard_address)
        regex = regex.gsub(Regexp.escape('%{key}'), "(.+)")
        Regexp.new(regex).freeze
      end
    end
  end
end
