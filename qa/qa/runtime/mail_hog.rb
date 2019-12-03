# frozen_string_literal: true
module QA
  module Runtime
    module MailHog
      def self.base_url
        host = QA::Runtime::Env.mailhog_hostname || 'localhost'
        "http://#{host}:8025"
      end

      def self.api_messages_url
        "#{base_url}/api/v2/messages"
      end
    end
  end
end
