# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    # This worker will be removed in 14.0
    class CounterJobWorker
      include ApplicationWorker

      feature_category :devops_reports
      urgency :low

      idempotent!

      def perform(*args)
        # Delegate to the new worker
        Analytics::UsageTrends::CounterJobWorker.new.perform(*args)
      end
    end
  end
end
