# frozen_string_literal: true

module Gitlab
  module EventStore
    class Subscription
      DEFAULT_GROUP_SIZE = 10
      SCHEDULING_BATCH_SIZE = 100
      SCHEDULING_BATCH_DELAY = 10.seconds

      attr_reader :worker, :condition, :delay, :group_size

      def initialize(worker, condition, delay, group_size)
        @worker = worker
        @condition = condition
        @delay = delay
        @group_size = group_size || DEFAULT_GROUP_SIZE
      end

      def consume_event(event)
        return unless condition_met?(event)

        if delay
          worker.perform_in(delay, event.class.name, event.data.deep_stringify_keys.to_h)
        else
          worker.perform_async(event.class.name, event.data.deep_stringify_keys.to_h)
        end

        # We rescue and track any exceptions here because we don't want to
        # impact other subscribers if one is faulty.
        # The method `condition_met?`, since it can run a block, it might encounter
        # a bug. By raising an exception here we could interrupt the publishing
        # process, preventing other subscribers from consuming the event.
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_class: event.class.name, event_data: event.data)
      end

      def consume_events(events)
        event_class = events.first.class
        unless events.all? { |e| e.class < Event && e.instance_of?(event_class) }
          raise InvalidEvent, "Events being published are not an instance of Gitlab::EventStore::Event"
        end

        matched_events = events.select { |event| condition_met?(event) }
        worker_args = events_worker_args(event_class, matched_events)

        # rubocop:disable Scalability/BulkPerformWithContext -- Context info is already available in `ApplicationContext` here.
        if worker_args.size > SCHEDULING_BATCH_SIZE
          # To reduce the number of concurrent jobs, we batch the group of events and add delay between each batch.
          # We add a delay of 1s as bulk_perform_in does not support 0s delay.
          worker.bulk_perform_in(delay || 1.second, worker_args, batch_size: SCHEDULING_BATCH_SIZE, batch_delay: SCHEDULING_BATCH_DELAY)
        elsif delay
          worker.bulk_perform_in(delay, worker_args)
        else
          worker.bulk_perform_async(worker_args)
        end
        # rubocop:enable Scalability/BulkPerformWithContext
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_class: event_class, events: events.map(&:data))
      end

      private

      def condition_met?(event)
        return true unless condition

        condition.call(event)
      end

      def events_worker_args(event_class, events)
        events
          .map { |event| event.data.deep_stringify_keys.to_h }
          .each_slice(group_size)
          .map { |events_data_group| [event_class.name, events_data_group] }
      end
    end
  end
end
