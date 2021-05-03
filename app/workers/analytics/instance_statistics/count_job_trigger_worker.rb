# frozen_string_literal: true

module Analytics
  module InstanceStatistics
    # This worker will be removed in 14.0
    class CountJobTriggerWorker
      include ApplicationWorker

      sidekiq_options retry: 3
      include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

      feature_category :devops_reports
      tags :exclude_from_kubernetes
      urgency :low

      idempotent!

      def perform
        # Delegate to the new worker
        Analytics::UsageTrends::CountJobTriggerWorker.new.perform
      end
    end
  end
end
