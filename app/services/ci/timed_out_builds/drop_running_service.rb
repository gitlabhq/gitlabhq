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

      # rubocop:disable CodeReuse/ActiveRecord -- We want to avoid misusage of this query
      def timed_out_builds(partition)
        Ci::Build
          .joins(:runtime_metadata)
          .where(
            "#{Ci::RunningBuild.table_name}.created_at + " \
              "INTERVAL '1 second' * #{Ci::Build.table_name}.timeout <= ?",
            Time.current - MINUTE_BUFFER
          )
          .where(Ci::Build.arel_table[:partition_id].eq(Ci::RunningBuild.arel_table[:partition_id]))
          .running
          .in_partition(partition.id)
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
