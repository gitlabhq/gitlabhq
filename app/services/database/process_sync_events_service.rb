# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- existing module that holds the related consistency check/fix services
  class ProcessSyncEventsService
    include ExclusiveLeaseGuard

    BATCH_SIZE = 1000

    # sync_classes_by_consumer maps a consumer (a column on the event table,
    # e.g. :ci) to the mirror class it writes, e.g. { ci: ::Ci::NamespaceMirror }.
    def initialize(sync_event_class, sync_classes_by_consumer)
      @sync_event_class = sync_event_class
      @sync_classes_by_consumer = sync_classes_by_consumer
      @results = {}
    end

    def execute
      # To prevent parallel processing over the same event table
      try_obtain_lease { process_consumers }

      enqueue_worker_if_there_still_event

      @results
    end

    private

    def process_consumers
      errors = []

      @sync_classes_by_consumer.each do |consumer, sync_class|
        process_events(consumer, sync_class)
      rescue StandardError => e
        # A failing consumer must not block the other consumers.
        errors << e
      end

      # Raising lets Sidekiq retry the job; consumers that already succeeded
      # are then a cheap no-op because their columns are already marked.
      raise errors.first if errors.any?
    end

    def process_events(consumer, sync_class)
      add_result(consumer, estimated_total_events: @sync_event_class.upper_bound_count(consumer))

      events = @sync_event_class.unprocessed_events_for(consumer).preload_synced_relation.first(BATCH_SIZE)

      add_result(consumer, consumable_events: events.size)

      return if events.empty?

      processed_events = []

      begin
        events.each do |event|
          sync_class.sync!(event)

          processed_events << event
        end
      ensure
        add_result(consumer, processed_events: processed_events.size)
        @sync_event_class.mark_records_processed(processed_events, consumer)
      end
    end

    def enqueue_worker_if_there_still_event
      return unless @sync_classes_by_consumer.keys.any? do |consumer|
        @sync_event_class.unprocessed_events_for(consumer).exists?
      end

      @sync_event_class.enqueue_worker
    end

    def lease_key
      "#{super}::#{@sync_event_class}"
    end

    def lease_timeout
      1.minute
    end

    def add_result(consumer, result)
      @results.merge!(result.transform_keys { |key| :"#{consumer}_#{key}" })
    end
  end
end
