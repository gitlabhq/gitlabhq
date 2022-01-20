# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyAllExpiredService
      include ::Gitlab::ExclusiveLeaseHelpers
      include ::Gitlab::LoopHelpers

      BATCH_SIZE = 100
      LOOP_TIMEOUT = 5.minutes
      SMALL_LOOP_LIMIT = 100
      LARGE_LOOP_LIMIT = 500
      EXCLUSIVE_LOCK_KEY = 'expired_job_artifacts:destroy:lock'
      LOCK_TIMEOUT = 6.minutes

      def initialize
        @removed_artifacts_count = 0
        @start_at = Time.current
        @loop_limit = ::Feature.enabled?(:ci_artifact_fast_removal_large_loop_limit, default_enabled: :yaml) ? LARGE_LOOP_LIMIT : SMALL_LOOP_LIMIT
      end

      ##
      # Destroy expired job artifacts on GitLab instance
      #
      # This destroy process cannot run for more than 6 minutes. This is for
      # preventing multiple `ExpireBuildArtifactsWorker` CRON jobs run concurrently,
      # which is scheduled every 7 minutes.
      def execute
        return 0 unless ::Feature.enabled?(:ci_destroy_all_expired_service, default_enabled: :yaml)

        in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
          if ::Feature.enabled?(:ci_destroy_unlocked_job_artifacts)
            destroy_unlocked_job_artifacts
          else
            destroy_job_artifacts_with_slow_iteration
          end
        end

        @removed_artifacts_count
      end

      private

      def destroy_unlocked_job_artifacts
        loop_until(timeout: LOOP_TIMEOUT, limit: @loop_limit) do
          artifacts = Ci::JobArtifact.expired_before(@start_at).artifact_unlocked.limit(BATCH_SIZE)
          service_response = destroy_batch(artifacts)
          @removed_artifacts_count += service_response[:destroyed_artifacts_count]
        end
      end

      def destroy_job_artifacts_with_slow_iteration
        Ci::JobArtifact.expired_before(@start_at).each_batch(of: BATCH_SIZE, column: :expire_at, order: :desc) do |relation, index|
          # For performance reasons, join with ci_pipelines after the batch is queried.
          # See: https://gitlab.com/gitlab-org/gitlab/-/merge_requests/47496
          artifacts = relation.unlocked

          service_response = destroy_batch(artifacts)
          @removed_artifacts_count += service_response[:destroyed_artifacts_count]

          break if loop_timeout?
          break if index >= @loop_limit
        end
      end

      def destroy_batch(artifacts)
        Ci::JobArtifacts::DestroyBatchService.new(artifacts).execute
      end

      def loop_timeout?
        Time.current > @start_at + LOOP_TIMEOUT
      end
    end
  end
end
