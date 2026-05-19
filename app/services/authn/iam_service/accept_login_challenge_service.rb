# frozen_string_literal: true

module Authn
  module IamService
    class AcceptLoginChallengeService
      ACCEPT_PATH = '/oauth2/internal/auth/requests/login/accept'

      def initialize(challenge:, user:, client: HttpClient.new)
        @challenge = challenge
        @user = user
        @client = client
      end

      def execute
        response = @client.put(
          path: ACCEPT_PATH,
          query_params: { challenge: @challenge },
          body: request_body
        )

        return http_error(response) unless response.success?

        redirect_to = Gitlab::Json.safe_parse(response.body)&.dig('redirect_to')

        return missing_redirect_error if redirect_to.blank?
        return invalid_redirect_error unless RedirectUrlValidator.valid?(redirect_to)

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue HttpClient::RequestError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      end

      private

      def request_body
        {
          id: @user.id.to_s,
          subject: @user.id.to_s,
          name: @user.name,
          email: @user.email
        }
      end

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM login accept failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

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

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM login challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
