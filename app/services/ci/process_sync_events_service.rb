# frozen_string_literal: true

module Ci
  class ProcessSyncEventsService
    include ExclusiveLeaseGuard

    BATCH_SIZE = 1000

    def initialize(sync_event_class, sync_class)
      @sync_event_class = sync_event_class
      @sync_class = sync_class
      @results = {}
    end

    def execute
      # To prevent parallel processing over the same event table
      try_obtain_lease { process_events }

      enqueue_worker_if_there_still_event

      @results
    end

    private

    def process_events
      add_result(estimated_total_events: @sync_event_class.upper_bound_count)

      events = @sync_event_class.unprocessed_events.preload_synced_relation.first(BATCH_SIZE)

      add_result(consumable_events: events.size)

      return if events.empty?

      processed_events = []

      begin
        events.each do |event|
          @sync_class.sync!(event)

          processed_events << event
        end
      ensure
        add_result(processed_events: processed_events.size)
        @sync_event_class.mark_records_processed(processed_events)
      end
    end

    def enqueue_worker_if_there_still_event
      @sync_event_class.enqueue_worker if @sync_event_class.unprocessed_events.exists?
    end

    def lease_key
      "#{super}::#{@sync_event_class}"
    end

    def lease_timeout
      1.minute
    end

    def add_result(result)
      @results.merge!(result)
    end
  end
end
