# frozen_string_literal: true

module Gitlab
  module Email
    class ServiceDeskReceiver < Receiver
      private

      def find_handler
        return unless service_desk_key

        Gitlab::Email::Handler::ServiceDeskHandler.new(mail, nil, service_desk_key: service_desk_key)
      end

      def service_desk_key
        strong_memoize(:service_desk_key) do
          find_service_desk_key
        end
      end

      def find_service_desk_key
        mail.to.find do |address|
          key = ::Gitlab::ServiceDeskEmail.key_from_address(address)
          break key if key
        end
      end
    end
  end
end
