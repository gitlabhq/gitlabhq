# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropRunningService
      include DropHelpers

      BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning running, timed-out builds"

        drop(running_timed_out_builds, failure_reason: :stuck_or_timeout_failure)
      end

      private

      def running_timed_out_builds
        if Feature.enabled?(:ci_new_query_for_running_stuck_jobs)
          Ci::Build
            .running
            .created_at_before(BUILD_RUNNING_OUTDATED_TIMEOUT.ago)
            .updated_at_before(BUILD_RUNNING_OUTDATED_TIMEOUT.ago)
            .order(created_at: :asc, project_id: :asc) # rubocop:disable CodeReuse/ActiveRecord
        else
          Ci::Build.running.updated_at_before(BUILD_RUNNING_OUTDATED_TIMEOUT.ago)
        end
      end
    end
  end
end
