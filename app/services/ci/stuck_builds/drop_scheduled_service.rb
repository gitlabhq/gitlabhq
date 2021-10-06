# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropScheduledService
      include DropHelpers

      BUILD_SCHEDULED_OUTDATED_TIMEOUT = 1.hour

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning scheduled, timed-out builds"

        drop(scheduled_timed_out_builds, failure_reason: :stale_schedule)
      end

      private

      def scheduled_timed_out_builds
        Ci::Build.scheduled.scheduled_at_before(BUILD_SCHEDULED_OUTDATED_TIMEOUT.ago)
      end
    end
  end
end
