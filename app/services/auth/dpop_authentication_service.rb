# frozen_string_literal: true

module Auth # rubocop:disable Gitlab/BoundedContexts -- following the same structure as other services
  class DpopAuthenticationService < ::BaseContainerService
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
      request.headers.fetch('dpop') { raise Gitlab::Auth::DpopValidationError, 'DPoP header is missing' }
    end
  end
end
