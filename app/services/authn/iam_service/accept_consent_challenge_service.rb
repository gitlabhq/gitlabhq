# frozen_string_literal: true

module Authn
  module IamService
    class AcceptConsentChallengeService
      # rubocop:disable Metrics/ParameterLists -- all arguments needed
      def initialize(
        challenge:, user:, granted_scopes:, client_id:, client_name:, requested_scopes:,
        client_scopes:, ip_address: nil, user_agent: nil, client: GrpcClient.new)
        # rubocop:enable Metrics/ParameterLists
        @challenge = challenge
        @user = user
        @granted_scopes = granted_scopes
        @client_id = client_id
        @client_name = client_name
        @requested_scopes = requested_scopes
        @client_scopes = client_scopes
        @ip_address = ip_address
        @user_agent = user_agent
        @client = client
      end

      def execute
        response = @client.accept_consent_challenge(
          challenge: @challenge,
          granted_scopes: @granted_scopes
        )

        redirect_to = response.redirect_to

        return missing_redirect_error if redirect_to.blank?
        return invalid_redirect_error unless RedirectUrlValidator.valid?(redirect_to)

        persist_consent_record!
        emit_audit_event

        ServiceResponse.success(payload: { redirect_to: redirect_to })
      rescue GrpcClient::RequestError => e
        log_failure(reason: 'grpc_error')
        ServiceResponse.error(message: e.message, reason: :service_unavailable)
      rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique => e
        Gitlab::ErrorTracking.track_exception(e)
        log_failure(reason: 'persistence_error')
        ServiceResponse.error(message: e.message, reason: :consent_record_invalid)
      end

      private

      def persist_consent_record!
        Authn::OauthConsent.create!(
          consent_challenge: @challenge,
          user: @user,
          client_id: @client_id,
          requested_scopes: @requested_scopes,
          granted_scopes: @granted_scopes,
          status: :authorized
        )
      end

      def emit_audit_event
        audit_context = {
          name: 'user_authorized_iam_oauth_application',
          author: @user,
          scope: @user,
          target: @user,
          target_details: @client_name,
          message: 'User authorized an OAuth application.',
          additional_details: {
            application_id: @client_id,
            application_name: @client_name,
            scopes: @client_scopes,
            requested_scopes: @requested_scopes,
            granted_scopes: @granted_scopes,
            user_agent: @user_agent
          },
          ip_address: @ip_address
        }

        ::Gitlab::Audit::Auditor.audit(audit_context)
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

      def log_failure(reason:)
        Gitlab::AuthLogger.error(
          message: 'IAM consent challenge accept failed',
          reason: reason,
          Labkit::Fields::GL_USER_ID => @user.id
        )
      end
    end
  end
end
