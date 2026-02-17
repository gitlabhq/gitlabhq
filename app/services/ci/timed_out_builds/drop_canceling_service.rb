# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropCancelingService
      include StuckBuilds::DropHelpers

      MINUTE_BUFFER = 15.minutes

      def execute
        return unless Feature.enabled?(:enforce_job_timeouts_on_canceling_jobs, :instance)

        Gitlab::AppLogger.info "#{self.class}: Cleaning timed-out canceling builds"

        Ci::Partition.find_each do |partition|
          drop_incomplete(timed_out_canceling_builds(partition), failure_reason: :job_execution_server_timeout)
        end
      end

      private

      def timed_out_canceling_builds(partition)
        # rubocop:disable CodeReuse/ActiveRecord -- We want to avoid misusage of this query
        Ci::Build
          .canceling
          .where(
            "#{Ci::Build.quoted_table_name}.started_at + INTERVAL \'1 second\' * #{Ci::Build.table_name}.timeout <= ?",
            Time.current - MINUTE_BUFFER
          )
          .in_partition(partition.id)
        # rubocop:enable CodeReuse/ActiveRecord
      end
    end
  end
end
