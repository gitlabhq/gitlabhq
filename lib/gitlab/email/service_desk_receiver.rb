# frozen_string_literal: true

module Gitlab
  module Email
    class ServiceDeskReceiver < Receiver
      private

      def handler
        return unless mail_key

        Gitlab::Email::Handler::ServiceDeskHandler.new(mail, nil, service_desk_key: mail_key)
      end
      strong_memoize_attr :handler

      def email_class
        ::Gitlab::Email::ServiceDeskEmail
      end
    end
  end
end
