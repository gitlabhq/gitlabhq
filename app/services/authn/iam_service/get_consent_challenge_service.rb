# frozen_string_literal: true

module Authn
  module IamService
    class GetConsentChallengeService
      MANDATORY_FIELDS = %i[
        subject requested_scopes client_id client_name client_owner client_created_at client_scopes
      ].freeze

      def initialize(challenge:, client: GrpcClient.new)
        @challenge = challenge
        @client = client
      end

      def execute
        response = @client.get_consent_challenge(challenge: @challenge)

        oauth_client = response.client

        payload = {
          skip_consent: response.skip,
          subject: response.subject.to_s,
          requested_scopes: response.requested_scopes.to_a,
          client_id: oauth_client&.client_id,
          client_name: oauth_client&.client_name,
          client_owner: oauth_client&.client_owner,
          client_created_at: oauth_client&.created_at && Time.zone.at(oauth_client.created_at.seconds),
          client_scopes: Array(oauth_client&.scopes&.to_a)
        }

        missing = MANDATORY_FIELDS.select { |f| payload[f].blank? }
        return missing_mandatory_fields_error(missing) if missing.any?

        ServiceResponse.success(payload: payload)
      rescue GrpcClient::RequestError => e
        log_failure(reason: 'grpc_error')
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      end

      private

      def missing_mandatory_fields_error(fields)
        log_failure(reason: 'missing_mandatory_fields')
        ServiceResponse.error(
          message: "IAM consent response missing mandatory fields: #{fields.join(', ')}",
          reason: :invalid_response
        )
      end

      def log_failure(reason:)
        Gitlab::AuthLogger.error(
          message: 'IAM consent request failed',
          reason: reason
        )
      end
    end
  end
end
