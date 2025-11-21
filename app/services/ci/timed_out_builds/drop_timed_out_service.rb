# frozen_string_literal: true

module Ci
  module TimedOutBuilds
    class DropTimedOutService
      include StuckBuilds::DropHelpers

      def execute
        return unless Feature.enabled?(:enforce_job_configured_timeouts, :instance)

        Gitlab::AppLogger.info "#{self.class}: Cleaning timed-out builds"

        Ci::Partition.find_each do |partition|
          drop(timed_out_builds(partition), failure_reason: :job_execution_timeout)
        end
      end

      def timed_out_builds(partition)
        Ci::Build
          .timed_out_builds
          .in_partition(partition.id)
      end
    end
  end
end
