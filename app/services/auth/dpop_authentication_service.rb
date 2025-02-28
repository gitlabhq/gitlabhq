# frozen_string_literal: true

module Auth # rubocop:disable Gitlab/BoundedContexts -- following the same structure as other services
  class DpopAuthenticationService < ::BaseContainerService
    # Demonstrating Proof of Possession (DPoP) blueprint:
    # https://gitlab.com/gitlab-com/gl-security/product-security/appsec/security-feature-blueprints/-/blob/main/sender_constraining_access_tokens/index.md

    def initialize(current_user:, personal_access_token_plaintext:, request:)
      @current_user = current_user
      @personal_access_token_plaintext = personal_access_token_plaintext
      @request = request
    end

    def execute
      return ServiceResponse.success unless current_user.dpop_enabled

      dpop_token = Gitlab::Auth::DpopToken.new(data: extract_dpop_from_request!(request))

      Gitlab::Auth::DpopTokenUser.new(token: dpop_token, user: current_user,
        personal_access_token_plaintext: personal_access_token_plaintext).validate!

      ServiceResponse.success
    end

    private

    attr_reader :current_user, :personal_access_token_plaintext, :request

    def extract_dpop_from_request!(request)
      dpop_token = request.headers.fetch('dpop') { raise Gitlab::Auth::DpopValidationError, 'DPoP header is missing' }

      # Ensure there is exactly one token
      if dpop_token.strip.match?(/[\s,]+/)
        raise Gitlab::Auth::DpopValidationError,
          'Only 1 DPoP header is allowed in request'
      end

      dpop_token
    end
  end
end
