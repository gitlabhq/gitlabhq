# frozen_string_literal: true

module Ci
  module StuckPipelines
    class ProcessWorker
      include ApplicationWorker
      include ExclusiveLeaseGuard

      idempotent!

      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- Instance wide cleanup worker

      feature_category :continuous_integration
      data_consistency :sticky

      def perform
        try_obtain_lease do
          Ci::StuckPipelines::ProcessService.new.execute
        end
      end

      private

      def lease_timeout
        30.minutes
      end
    end
  end
end
