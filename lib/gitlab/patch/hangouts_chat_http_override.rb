# frozen_string_literal: true

module Gitlab
  module Patch
    module HangoutsChatHTTPOverride
      attr_reader :uri

      # See https://github.com/enzinia/hangouts-chat/blob/6a509f61a56e757f8f417578b393b94423831ff7/lib/hangouts_chat/http.rb
      def post(payload)
        httparty_response = Gitlab::HTTP.post(
          uri,
          body: payload.to_json,
          headers: { 'Content-Type' => 'application/json' },
          parse: nil # Disables automatic response parsing
        )
        httparty_response.response
        # The rest of the integration expects a Net::HTTP response
      end
    end
  end
end
