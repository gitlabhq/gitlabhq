# frozen_string_literal: true

module HangoutsChat
  class Sender
    class HTTP
      module GitlabHTTPOverride
        extend ::Gitlab::Utils::Override

        attr_reader :uri

        # see https://github.com/enzinia/hangouts-chat/blob/6a509f61a56e757f8f417578b393b94423831ff7/lib/hangouts_chat/http.rb
        override :post
        def post(payload)
          httparty_response = Gitlab::HTTP.post(
            uri,
            body: payload.to_json,
            headers: { 'Content-Type' => 'application/json' },
            parse: nil # disables automatic response parsing
          )
          net_http_response = httparty_response.response
          # The rest of the integration expects a Net::HTTP response
          net_http_response
        end
      end

      prepend GitlabHTTPOverride
    end
  end
end
