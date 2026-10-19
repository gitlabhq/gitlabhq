# frozen_string_literal: true

module Authz
  module OauthConsentGrants
    class RevokeService
      def initialize(user:, application_id:, author: user, revocation_source: :user, ip_address: nil)
        @user = user
        @application_id = application_id
        @author = author
        @revocation_source = revocation_source
        @ip_address = ip_address
      end

      def execute
        grant = Authz::OauthConsentGrant.active_for_user_and_application(user.id, application_id)
        return ServiceResponse.success(payload: { consent_grant: nil }) unless grant

        Authz::OauthConsentGrant.transaction do
          grant.revoked!
          Authn::OauthApplication.revoke_tokens_and_grants_for(grant.application_id, user)
        end

        audit(grant)

        ServiceResponse.success(payload: { consent_grant: grant })
      end

      private

      attr_reader :user, :application_id, :author, :revocation_source, :ip_address

      def audit(grant)
        ::Gitlab::Audit::Auditor.audit(
          name: 'oauth_consent_grant_revoked',
          author: author,
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
            revocation_source: revocation_source.to_s,
            granular_scopes: grant.granular_scopes.map { |scope| scope.slice(:access, :namespace_id, :permissions) }
          },
          ip_address: ip_address
        )
      end
    end
  end
end
