# frozen_string_literal: true

module Authn
  module OauthApplications
    class RevokeService
      attr_reader :current_user, :application_id

      def initialize(current_user:, application_id:)
        @current_user = current_user
        @application_id = application_id
      end

      def execute
        ApplicationRecord.transaction do
          Authn::OauthApplication.revoke_tokens_and_grants_for(application_id, current_user)
          revoke_consents if Feature.enabled?(:iam_svc_oauth, current_user)
        end

        log_event

        ServiceResponse.success
      end

      private

      def revoke_consents
        client_id = Authn::OauthApplication.uid_for(application_id)
        return if client_id.blank?

        Authn::OauthConsent.revoke_authorized_for(user: current_user, client_id: client_id)
      end

      def log_event
        Gitlab::AppLogger.info(
          Labkit::Fields::CLASS_NAME => self.class.name,
          message: "OAuth application authorization revoked",
          revoked_by: current_user.username,
          revoked_for: current_user.username,
          application_id: application_id)
      end
    end
  end
end

Authn::OauthApplications::RevokeService.prepend_mod_with('Authn::OauthApplications::RevokeService')
