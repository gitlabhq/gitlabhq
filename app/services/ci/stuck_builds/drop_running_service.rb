# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropRunningService
      include DropHelpers

      BUILD_RUNNING_OUTDATED_TIMEOUT = 1.hour

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning running, timed-out builds"

        Ci::Partition.find_each do |partition|
          drop(running_stuck_builds(partition), failure_reason: :stuck_or_timeout_failure)
        end
      end

      private

      def running_stuck_builds(partition)
        Ci::Build
          .not_timed_out_builds
          .updated_at_before(BUILD_RUNNING_OUTDATED_TIMEOUT.ago)
          .in_partition(partition.id)
      end
    end
  end
end
