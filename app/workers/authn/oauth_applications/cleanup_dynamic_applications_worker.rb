# frozen_string_literal: true

module Authn
  module OauthApplications
    # Destroys all dynamic OAuth applications (those created via the DCR endpoint,
    # where dynamic = true) and revokes their tokens and grants.
    #
    # This worker is triggered by an instance-wide admin setting
    # (dynamic_client_registration_enabled), which only exists on Self-Managed and
    # Dedicated instances. It is not used on GitLab.com, where DCR is controlled at
    # the organization (top-level group) level instead. Cross-organization iteration
    # is therefore acceptable here.
    class CleanupDynamicApplicationsWorker
      include ApplicationWorker

      idempotent!
      deduplicate :until_executing, including_scheduled: true
      data_consistency :sticky
      feature_category :system_access
      urgency :low
      concurrency_limit -> { 1 }
      defer_on_database_health_signal :gitlab_main, [:oauth_applications], 5.minutes

      MAX_RUNTIME = 3.minutes
      REQUEUE_DELAY = 3.minutes

      def perform
        runtime_limiter = Gitlab::Metrics::RuntimeLimiter.new(MAX_RUNTIME)

        Authn::OauthApplication.dynamic.each_batch do |batch|
          uids = batch.pluck(:uid) if Feature.enabled?(:iam_svc_oauth, :instance) # rubocop:disable CodeReuse/ActiveRecord -- pluck on batch relation, not a model query

          batch.each do |application|
            revoke_all_tokens_and_grants(application.id)
            application.delete
          end

          Authn::OauthConsent.revoke_authorized_for(client_id: uids) if uids

          if runtime_limiter.over_time?
            self.class.perform_in(REQUEUE_DELAY)
            break
          end
        end
      end

      private

      # Revokes all access tokens and grants for the given application,
      # regardless of resource owner. Called before application.delete so that
      # revoked_at is stamped on the rows before the application is removed.
      # (destroy! would cascade via dependent: :delete_all and wipe the rows
      # before revocation, losing the audit trail.)
      def revoke_all_tokens_and_grants(application_id)
        # rubocop: disable CodeReuse/ActiveRecord -- bulk revocation without resource_owner filter
        OauthAccessToken.where(application_id: application_id, revoked_at: nil)
                        .update_all(revoked_at: Time.current)
        OauthAccessGrant.where(application_id: application_id, revoked_at: nil)
                        .update_all(revoked_at: Time.current)
        # rubocop: enable CodeReuse/ActiveRecord
      end
    end
  end
end
