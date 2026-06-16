# frozen_string_literal: true

module Authn
  module IamService
    class AcceptLoginChallengeService
      def initialize(challenge:, user:, client: GrpcClient.new)
        @challenge = challenge
        @user = user
        @client = client
      end

      def execute
        response = @client.accept_login_challenge(
          challenge: @challenge,
          subject: @user.id.to_s,
          name: @user.name,
          email: @user.email
        )

        redirect_to = response.redirect_to

        return missing_redirect_error if redirect_to.blank?
        return invalid_redirect_error unless RedirectUrlValidator.valid?(redirect_to)

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue GrpcClient::RequestError => e
        log_failure(reason: 'grpc_error')
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      end

      private

      def missing_redirect_error
        log_failure(reason: 'missing_redirect_to')
        ServiceResponse.error(
          message: 'IAM login accept response missing redirect_to',
          reason: :invalid_response
        )
      end

      def invalid_redirect_error
        log_failure(reason: 'invalid_redirect_url')
        ServiceResponse.error(
          message: 'IAM login accept response contains invalid redirect URL',
          reason: :invalid_redirect_url
        )
      end

      def log_failure(reason:)
        Gitlab::AuthLogger.error(
          message: 'IAM login challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id
        )
      end
    end
  end
end
