# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropRunningService
      include StuckBuilds::DropHelpers

      MINUTE_BUFFER = 15.minutes

      def execute
        Gitlab::AppLogger.info "#{self.class}: Cleaning timed-out builds"

        Ci::Partition.find_each do |partition|
          drop(timed_out_builds(partition), failure_reason: :server_timeout_running)
        end
      end

      # rubocop:disable CodeReuse/ActiveRecord -- We want to avoid misusage of this query
      # We must write this query using a lateral join for PG18.
      # See https://gitlab.com/gitlab-org/gitlab/-/issues/605358.
      def timed_out_builds(partition)
        running_builds = Ci::RunningBuild.in_partition(partition.id)

        lateral = Ci::Build
          .in_partition(partition.id)
          .running
          .where(Ci::Build.arel_table[:id].eq(Ci::RunningBuild.arel_table[:build_id]))
          .where(Ci::Build.arel_table[:partition_id].eq(Ci::RunningBuild.arel_table[:partition_id]))
          .where(
            "#{Ci::RunningBuild.table_name}.created_at + " \
              "INTERVAL '1 second' * #{Ci::Build.table_name}.timeout <= ?",
            Time.current - MINUTE_BUFFER
          )
          .limit(1)

        Ci::Build
          .from("(#{running_builds.select(:build_id, :partition_id, :created_at).to_sql}) #{Ci::RunningBuild.table_name}")
          .joins("JOIN LATERAL (#{lateral.to_sql}) #{Ci::Build.table_name} ON TRUE")
      end
      # rubocop:enable CodeReuse/ActiveRecord
    end
  end
end
