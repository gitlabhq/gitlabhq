module Gitlab
  module ReplyByEmail
    class << self
      def enabled?
        config.enabled && address_formatted_correctly?
      end

      def address_formatted_correctly?
        config.address &&
          config.address.include?("%{reply_key}")
      end

      def reply_key
        return nil unless enabled?

        SecureRandom.hex(16)
      end

      def reply_address(reply_key)
        config.address.gsub('%{reply_key}', reply_key)
      end

      def reply_key_from_address(address)
        regex = address_regex
        return unless regex

        match = address.match(regex)
        return unless match

        match[1]
      end

      private

      def config
        Gitlab.config.reply_by_email
      end

      def address_regex
        wildcard_address = config.address
        return nil unless wildcard_address

        regex = Regexp.escape(wildcard_address)
        regex = regex.gsub(Regexp.escape('%{reply_key}'), "(.+)")
        Regexp.new(regex).freeze
      end
    end
  end
end
