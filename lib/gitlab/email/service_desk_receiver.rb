# frozen_string_literal: true

module Gitlab
  module Email
    class ServiceDeskReceiver < Receiver
      private

      def find_handler(mail)
        key = service_desk_key(mail)
        return unless key

        Gitlab::Email::Handler::ServiceDeskHandler.new(mail, nil, service_desk_key: key)
      end

      def service_desk_key(mail)
        mail.to.find do |address|
          key = ::Gitlab::ServiceDeskEmail.key_from_address(address)
          break key if key
        end
      end
    end
  end
end
