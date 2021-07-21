# frozen_string_literal: true

module Namespaces
  class PruneAggregationSchedulesWorker # rubocop:disable Scalability/IdempotentWorker
    include ApplicationWorker

    data_consistency :always

    sidekiq_options retry: 3
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext

    feature_category :source_code_management
    worker_resource_boundary :cpu

    # Worker to prune pending rows on Namespace::AggregationSchedule
    # It's scheduled to run once a day at 1:05am.
    def perform
      aggregation_schedules.find_each do |aggregation_schedule|
        aggregation_schedule.schedule_root_storage_statistics
      end
    end

    private

    def aggregation_schedules
      Namespace::AggregationSchedule.all
    end
  end
end
