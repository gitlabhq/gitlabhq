# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropRunningWorker
      include ApplicationWorker

      idempotent!

      # rubocop:disable Scalability/CronWorkerContext
      # This is an instance-wide cleanup query, so there's no meaningful
      # scope to consider this in the context of.
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      data_consistency :always

      feature_category :continuous_integration

      EXCLUSIVE_LEASE_KEY = 'ci_stuck_builds_drop_running_worker_lease'

      def perform
        return unless try_obtain_lease

        begin
          Ci::StuckBuilds::DropRunningService.new.execute
        ensure
          remove_lease
        end
      end

      private

      def try_obtain_lease
        @uuid = Gitlab::ExclusiveLease.new(EXCLUSIVE_LEASE_KEY, timeout: 30.minutes).try_obtain
      end

      def remove_lease
        Gitlab::ExclusiveLease.cancel(EXCLUSIVE_LEASE_KEY, @uuid)
      end
    end
  end
end
