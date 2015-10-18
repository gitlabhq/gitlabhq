module Gitlab
  module IncomingEmail
    class << self
      def enabled?
        config.enabled && address_formatted_correctly?
      end

      def address_formatted_correctly?
        config.address &&
          config.address.include?("%{key}")
      end

      def reply_address(key)
        config.address.gsub('%{key}', key)
      end

      def key_from_address(address)
        regex = address_regex
        return unless regex

        match = address.match(regex)
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
