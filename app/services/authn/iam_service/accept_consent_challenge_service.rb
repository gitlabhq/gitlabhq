# frozen_string_literal: true

module Authn
  module IamService
    class AcceptConsentChallengeService
      ACCEPT_PATH = '/oauth2/internal/auth/requests/consent/accept'

      def initialize(challenge:, user:, granted_scope:, client: HttpClient.new)
        @challenge = challenge
        @user = user
        @granted_scope = granted_scope
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

        # TODO: handle consent record
        # TODO: handle audit event

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue HttpClient::RequestError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      end

      private

      def request_body
        {
          grant_scope: @granted_scope,
          session: {
            access_token: { username: @user.username },
            id_token: { name: @user.name, email: @user.email }
          }
        }
      end

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM consent accept failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

      def missing_redirect_error
        log_failure(reason: 'missing_redirect_to')
        ServiceResponse.error(
          message: 'IAM consent accept response missing redirect_to',
          reason: :invalid_response
        )
      end

      def invalid_redirect_error
        log_failure(reason: 'invalid_redirect_url')
        ServiceResponse.error(
          message: 'IAM consent accept response contains invalid redirect URL',
          reason: :invalid_redirect_url
        )
      end

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM consent challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
