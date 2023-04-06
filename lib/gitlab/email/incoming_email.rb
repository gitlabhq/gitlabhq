# frozen_string_literal: true

module Gitlab
  module Email
    module IncomingEmail
      class << self
        include Gitlab::Email::Common

        def config
          incoming_email_config
        end

        def key_from_address(address, wildcard_address: nil)
          wildcard_address ||= config.address
          regex = address_regex(wildcard_address)
          return unless regex

          match = address.match(regex)
          return unless match

          match[1]
        end

        private

        def address_regex(wildcard_address)
          return unless wildcard_address

          regex = Regexp.escape(wildcard_address)
          regex = regex.sub(Regexp.escape(WILDCARD_PLACEHOLDER), '(.+)')
          Regexp.new(/\A<?#{regex}>?\z/).freeze
        end
      end
    end
  end
end
