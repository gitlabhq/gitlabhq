# frozen_string_literal: true

module Namespaces
  class UpdateRootStatisticsWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :always

    idempotent!

    feature_category :source_code_management

    def handle_event(event)
      ScheduleAggregationWorker.perform_async(event.data[:namespace_id])
    end
  end
end
