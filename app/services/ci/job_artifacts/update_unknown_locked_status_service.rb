# frozen_string_literal: true

module Ci
  module JobArtifacts
    class UpdateUnknownLockedStatusService
      include ::Gitlab::ExclusiveLeaseHelpers
      include ::Gitlab::LoopHelpers

      BATCH_SIZE = 100
      LOOP_TIMEOUT = 5.minutes
      LOOP_LIMIT = 100
      LARGE_LOOP_LIMIT = 500
      EXCLUSIVE_LOCK_KEY = 'unknown_status_job_artifacts:update:lock'
      LOCK_TIMEOUT = 6.minutes

      def initialize
        @removed_count = 0
        @locked_count = 0
        @start_at = Time.current
        @loop_limit = if Feature.enabled?(:ci_job_artifacts_backlog_large_loop_limit, type: :ops)
                        LARGE_LOOP_LIMIT
                      else
                        LOOP_LIMIT
                      end
      end

      def execute
        in_lock(EXCLUSIVE_LOCK_KEY, ttl: LOCK_TIMEOUT, retries: 1) do
          update_locked_status_on_unknown_artifacts
        end

        { removed: @removed_count, locked: @locked_count }
      end

      private

      def update_locked_status_on_unknown_artifacts
        loop_until(timeout: LOOP_TIMEOUT, limit: @loop_limit) do
          unknown_status_build_ids = safely_ordered_ci_job_artifacts_locked_unknown_relation.pluck_job_id.uniq

          locked_pipe_build_ids = ::Ci::Build
                                    .with_pipeline_locked_artifacts
                                    .id_in(unknown_status_build_ids)
                                    .pluck_primary_key

          @locked_count += update_unknown_artifacts(locked_pipe_build_ids, Ci::JobArtifact.lockeds[:artifacts_locked])

          unlocked_pipe_build_ids = unknown_status_build_ids - locked_pipe_build_ids
          service_response = batch_destroy_artifacts(unlocked_pipe_build_ids)
          @removed_count += service_response[:destroyed_artifacts_count]
        end
      end

      def update_unknown_artifacts(build_ids, locked_value)
        return 0 unless build_ids.any?

        expired_locked_unknown_artifacts.for_job_ids(build_ids).update_all(locked: locked_value)
      end

      def batch_destroy_artifacts(build_ids)
        deleteable_artifacts_relation =
          if build_ids.any?
            expired_locked_unknown_artifacts.for_job_ids(build_ids)
          else
            Ci::JobArtifact.none
          end

        Ci::JobArtifacts::DestroyBatchService.new(deleteable_artifacts_relation).execute
      end

      def expired_locked_unknown_artifacts
        # UPDATE queries perform better without the specific order and limit
        # https://gitlab.com/gitlab-org/gitlab/-/merge_requests/76509#note_891260455
        Ci::JobArtifact.expired_before(@start_at).artifact_unknown
      end

      def safely_ordered_ci_job_artifacts_locked_unknown_relation
        # Adding the ORDER and LIMIT improves performance when we don't have build_id
        expired_locked_unknown_artifacts.limit(BATCH_SIZE).order_expired_asc
      end
    end
  end
end
