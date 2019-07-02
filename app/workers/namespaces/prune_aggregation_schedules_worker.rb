# frozen_string_literal: true

module Namespaces
  class PruneAggregationSchedulesWorker
    include ApplicationWorker
    include CronjobQueue

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
