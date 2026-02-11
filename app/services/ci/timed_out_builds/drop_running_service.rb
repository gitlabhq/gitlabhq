# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropRunningService
      include StuckBuilds::DropHelpers

      MINUTE_BUFFER = 15.minutes

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning timed-out builds"

        Ci::Partition.find_each do |partition|
          drop_incomplete(timed_out_builds(partition), failure_reason: :job_execution_timeout)
        end
      end

      def timed_out_builds(partition)
        Ci::Build
          .timed_out_running_builds(MINUTE_BUFFER)
          .in_partition(partition.id)
      end
    end
  end
end
