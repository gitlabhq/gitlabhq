# frozen_string_literal: true

module Ci
  module StuckBuilds
    class DropRunningWorker
      include ApplicationWorker
      include ExclusiveLeaseGuard

      idempotent!

      # rubocop:disable Scalability/CronWorkerContext
      # This is an instance-wide cleanup query, so there's no meaningful
      # scope to consider this in the context of.
      include CronjobQueue
      # rubocop:enable Scalability/CronWorkerContext

      data_consistency :always

      feature_category :continuous_integration

      def perform
        try_obtain_lease do
          Ci::StuckBuilds::DropRunningService.new.execute
        end
      end

      private

      def lease_timeout
        30.minutes
      end
    end
  end
end
