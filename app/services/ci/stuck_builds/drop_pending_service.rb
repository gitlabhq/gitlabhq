# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropPendingService
      include DropHelpers

      BUILD_PENDING_OUTDATED_TIMEOUT = 1.day
      BUILD_PENDING_STUCK_TIMEOUT = 1.hour

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning pending timed-out builds"

        drop(
          pending_builds(BUILD_PENDING_OUTDATED_TIMEOUT.ago),
          failure_reason: :stuck_or_timeout_failure
        )

        if Feature.enabled?(:drop_stuck_builds_from_ci_pending_builds_queue, :instance)
          drop_stuck_from_queue(
            pending_builds_queue(BUILD_PENDING_STUCK_TIMEOUT.ago),
            failure_reason: :stuck_or_timeout_failure
          )
        else
          drop_stuck(
            pending_builds(BUILD_PENDING_STUCK_TIMEOUT.ago),
            failure_reason: :stuck_or_timeout_failure
          )
        end
      end

      private

      # rubocop: disable CodeReuse/ActiveRecord
      # We're adding the ordering clause by `created_at` and `project_id`
      # because we want to force the query planner to use the
      # `ci_builds_gitlab_monitor_metrics` index all the time.
      def pending_builds(timeout)
        Ci::Build
          .pending
          .created_at_before(timeout)
          .updated_at_before(timeout)
          .order(created_at: :asc, project_id: :asc)
      end

      def pending_builds_queue(timeout)
        Ci::PendingBuild.where(created_at: ...timeout)
      end
      # rubocop: enable CodeReuse/ActiveRecord
    end
  end
end
