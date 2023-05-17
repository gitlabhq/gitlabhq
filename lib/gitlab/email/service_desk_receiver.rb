# frozen_string_literal: true

module Gitlab
  module Email
    class ServiceDeskReceiver < Receiver
      private

      def find_handler
        return unless mail_key

        Gitlab::Email::Handler::ServiceDeskHandler.new(mail, nil, service_desk_key: mail_key)
      end

      def email_class
        ::Gitlab::Email::ServiceDeskEmail
      end
    end
  end
end
