# frozen_string_literal: true

module Authn
  module IamService
    class GetConsentChallengeService
      CONSENT_REQUEST_PATH = '/oauth2/internal/auth/requests/consent'

      def initialize(challenge:, client: HttpClient.new)
        @challenge = challenge
        @client = client
      end

      def execute
        response = @client.get(
          path: CONSENT_REQUEST_PATH,
          query_params: { consent_challenge: @challenge }
        )

        return http_error(response) unless response.success?

        parsed = Gitlab::Json.safe_parse(response.body)

        return invalid_body_error unless parsed.is_a?(Hash)

        ServiceResponse.success(payload: {
          skip: parsed['skip'] == true,
          subject: parsed['subject'].to_s,
          requested_scope: Array(parsed['requested_scope']),
          client: parsed['client']
        })
      rescue HttpClient::RequestError => e
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      end

      private

      def http_error(response)
        log_failure(reason: 'http_error', http_status: response.code)
        ServiceResponse.error(
          message: "IAM consent request failed: HTTP #{response.code}",
          reason: :iam_request_failed
        )
      end

      def invalid_body_error
        log_failure(reason: 'invalid_response_body')
        ServiceResponse.error(
          message: 'IAM consent request response has invalid body',
          reason: :invalid_response
        )
      end

      def log_failure(reason:, http_status: nil)
        Gitlab::AuthLogger.error(
          message: 'IAM consent request failed',
          reason: reason,
          Labkit::Fields::HTTP_STATUS_CODE => http_status
        )
      end
    end
  end
end
