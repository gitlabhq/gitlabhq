# frozen_string_literal: true

module Ci
  module JobArtifacts
    class DestroyAllExpiredService
      include ::Gitlab::ExclusiveLeaseHelpers
      include ::Gitlab::LoopHelpers

      BATCH_SIZE = 100
      LOOP_LIMIT = 500
      LOOP_TIMEOUT = 5.minutes
      LOCK_TIMEOUT = 6.minutes
      EXCLUSIVE_LOCK_KEY = 'expired_job_artifacts:destroy:lock'

      def initialize
        @removed_artifacts_count = 0
        @start_at = Time.current
      end

      ##
      # Destroy expired job artifacts on GitLab instance
      #
      # This destroy process cannot run for more than 6 minutes. This is for
      # preventing multiple `ExpireBuildArtifactsWorker` CRON jobs run concurrently,
      # which is scheduled every 7 minutes.
      def execute
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
        loop_until(timeout: LOOP_TIMEOUT, limit: LOOP_LIMIT) do
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
          break if index >= LOOP_LIMIT
        end
      end

      def destroy_batch(artifacts)
        Ci::JobArtifacts::DestroyBatchService.new(artifacts, skip_projects_on_refresh: true).execute
      end

      def loop_timeout?
        Time.current > @start_at + LOOP_TIMEOUT
      end
    end
  end
end
