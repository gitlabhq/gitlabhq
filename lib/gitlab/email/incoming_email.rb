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
          ::Gitlab::EmailHandler::MailKey.key_from_address(address, wildcard_address)
        end
      end
    end
  end
end
