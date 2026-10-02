# frozen_string_literal: true

module Authz
  class ReverifyProjectAuthorizationsCronWorker
    include ApplicationWorker
    include LoopWithRuntimeLimit
    include CronjobQueue

    data_consistency :sticky
    feature_category :permissions
    idempotent!
    deduplicate :until_executing
    concurrency_limit -> { 10 }

    MAX_RUNTIME = 200.seconds

    def perform
      return if Feature.enabled?(:do_not_run_safety_net_auth_refresh_jobs, :instance)

      requeue_abandoned

      users_processed = 0
      queue_lag_s = nil

      result = loop_with_runtime_limit(MAX_RUNTIME) do
        batch = Authz::ProjectAuthorizationReverification.claim_batch
        break :complete if batch.empty?

        queue_lag_s ||= lag_seconds(batch)

        batch.each do |reverification|
          users_processed += 1 if process(reverification)
        end
      end

      queue_drained = result == :complete &&
        !Authz::ProjectAuthorizationReverification.to_be_processed.exists?

      log_extra_metadata_on_done(:users_processed, users_processed)
      log_extra_metadata_on_done(:queue_drained, queue_drained)
      log_extra_metadata_on_done(:queue_lag_s, queue_lag_s || 0)
    end

    private

    def lag_seconds(batch)
      processed_at = batch.map(&:enqueued_at).min + Authz::ProjectAuthorizationReverification::MIN_AGE

      (Time.current - processed_at).round
    end

    def process(reverification)
      refresh_authorizations(reverification.user)
      reverification.processed

      true
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, user_id: reverification.user_id)

      false
    end

    def refresh_authorizations(user)
      return unless user

      Gitlab::ApplicationContext.with_raw_context(
        authorized_projects_refresh_purpose: UserProjectAccessChangedService::SAFETY_NET_REFRESH_PURPOSE
      ) do
        with_context(user: user, related_class: self.class.name) do
          Users::RefreshAuthorizedProjectsService.new(user, source: self.class.name).execute
        end
      end
    end

    def requeue_abandoned
      Authz::ProjectAuthorizationReverification.abandoned.each_batch do |batch|
        batch.update_all(status: :pending, refresh_started_at: nil)
      end
    end
  end
end
