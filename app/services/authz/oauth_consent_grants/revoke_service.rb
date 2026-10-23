# frozen_string_literal: true

module Authz
  module OauthConsentGrants
    class RevokeService
      def initialize(user:, application_id:)
        @user = user
        @application_id = application_id
      end

      def execute
        grant = Authz::OauthConsentGrant.active_for_user_and_application(user.id, application_id)
        return ServiceResponse.success(payload: { consent_grant: nil }) unless grant

        # Loaded for the audit event before the delete cascades to the copied scopes.
        grant.granular_scopes.load

        Authz::OauthConsentGrant.transaction do
          grant.destroy!
          Authn::OauthApplication.revoke_tokens_and_grants_for(grant.application_id, user)
        end

        audit(grant)

        ServiceResponse.success(payload: { consent_grant: grant })
      end

      private

      attr_reader :user, :application_id

      def audit(grant)
        ::Gitlab::Audit::Auditor.audit(
          name: 'oauth_consent_grant_revoked',
          author: user,
          scope: user,
          target: grant,
          target_details: grant.application.name,
          message: 'Consent for an OAuth application was revoked.',
          additional_details: {
            application_id: grant.application_id,
            application_name: grant.application.name,
            application_owner_type: grant.application.owner_type,
            application_owner_id: grant.application.owner_id,
            source: grant.source,
            granular_scopes: grant.granular_scopes.map { |scope| scope.slice(:access, :namespace_id, :permissions) }
          }
        )
      end
    end
  end
end
