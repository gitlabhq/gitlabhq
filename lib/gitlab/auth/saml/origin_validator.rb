# frozen_string_literal: true

module Gitlab
  module Auth
    module Saml
      class OriginValidator
        AUTH_REQUEST_SESSION_KEY = "last_authn_request_id"

        def initialize(session)
          @session = session || {}
        end

        def store_origin(authn_request)
          session[AUTH_REQUEST_SESSION_KEY] = authn_request.uuid
        end

        def gitlab_initiated?(saml_response)
          return false if identity_provider_initiated?(saml_response)

          matches?(saml_response)
        end

        private

        attr_reader :session

        def matches?(saml_response)
          saml_response.in_response_to == expected_request_id
        end

        def identity_provider_initiated?(saml_response)
          saml_response.in_response_to.blank?
        end

        def expected_request_id
          session[AUTH_REQUEST_SESSION_KEY]
        end
      end
    end
  end
end
