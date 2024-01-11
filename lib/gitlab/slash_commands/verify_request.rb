# frozen_string_literal: true

module Gitlab
  module SlashCommands
    class VerifyRequest
      attr_accessor :integration, :chat_name, :response_url

      def initialize(integration, chat_name, response_url = nil)
        @integration = integration
        @chat_name = chat_name
        @response_url = response_url
      end

      def approve!
        update_token!
        update_source_message
      end

      def valid?
        return false if integration.token.nil? || chat_name.token.nil?

        ActiveSupport::SecurityUtils.secure_compare(integration.token, chat_name.token)
      end

      private

      def update_token!
        chat_name.update!(token: integration.token)
      end

      def update_source_message
        request_body = Gitlab::Json.dump(verified_request_body)

        Gitlab::HTTP.post(response_url, body: request_body, headers: headers)
      end

      def verified_request_body
        {
          'replace_original' => 'true',
          'text' => _("You've successfully verified! You now have access to slash commands. " \
                      "Thanks for helping ensure security!")
        }
      end

      def headers
        { 'Content-Type' => 'application/json' }
      end
    end
  end
end
