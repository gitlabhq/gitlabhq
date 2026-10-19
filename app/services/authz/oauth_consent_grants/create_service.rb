# frozen_string_literal: true

module Authz
  module OauthConsentGrants
    class CreateService
      def initialize(user:, application:, source: :doorkeeper, ip_address: nil)
        @user = user
        @application = application
        @source = source
        @ip_address = ip_address
      end

      def execute
        return error(_('Fine-grained OAuth tokens are disabled.'), :feature_disabled) if feature_disabled?
        return error(_('Per-session consent grants are not supported.'), :unsupported_source) if duo_session?

        if declared_scopes.empty?
          return error(_('The application does not declare any granular scopes.'), :no_granular_scopes)
        end

        previous_grant = nil
        grant = nil

        Authz::OauthConsentGrant.transaction do
          previous_grant = Authz::OauthConsentGrant.active_for_user_and_application(user.id, application.id)
          previous_grant&.revoked!

          grant = build_grant
          grant.save!
        end

        # Granular tokens resolve the new grant on their next request, legacy ones must not outlive the consent.
        # Revoked asynchronously since a user can hold tens of thousands of legacy tokens.
        Authn::OauthApplications::RevokeNonGranularTokensWorker.perform_async(application.id, user.id)

        audit(grant, previous_grant)

        ServiceResponse.success(payload: { consent_grant: grant, previous_grant: previous_grant })
      rescue ActiveRecord::RecordNotUnique
        error(_('An active consent grant for this application already exists.'), :conflict)
      rescue ActiveRecord::RecordInvalid => e
        error(e.record.errors.full_messages.to_sentence, :invalid)
      end

      private

      attr_reader :user, :application, :source, :ip_address

      def feature_disabled?
        Feature.disabled?(:granular_oauth_tokens, user)
      end

      def duo_session?
        source.to_s == 'duo_session'
      end

      def declared_scopes
        @declared_scopes ||= application.granular_scopes.to_a
      end

      def build_grant
        grant = Authz::OauthConsentGrant.new(user: user, application: application, source: source)
        grant.granular_scopes = declared_scopes.map do |granular_scope|
          granular_scope.build_copy.tap { |copy| copy.organization_id = user.organization_id }
        end

        grant
      end

      def audit(grant, previous_grant)
        ::Gitlab::Audit::Auditor.audit(
          name: previous_grant ? 'oauth_consent_grant_amended' : 'oauth_consent_grant_created',
          author: user,
          scope: user,
          target: grant,
          target_details: application.name,
          message: audit_message(previous_grant),
          additional_details: audit_details(grant, previous_grant),
          ip_address: ip_address
        )
      end

      def audit_message(previous_grant)
        if previous_grant
          'User amended consent for an OAuth application.'
        else
          'User granted consent to an OAuth application.'
        end
      end

      def audit_details(grant, previous_grant)
        details = {
          application_id: application.id,
          application_name: application.name,
          application_owner_type: application.owner_type,
          application_owner_id: application.owner_id,
          source: grant.source,
          granular_scopes: grant.oauth_consent_grant_granular_scopes.map do |link|
            link.granular_scope.slice(:access, :namespace_id, :permissions)
          end
        }
        details[:previous_grant_id] = previous_grant.id if previous_grant
        details
      end

      def error(message, reason)
        ServiceResponse.error(message: message, reason: reason)
      end
    end
  end
end
