# frozen_string_literal: true

module Gitlab
  module EventStore
    class Subscription
      attr_reader :worker, :condition

      def initialize(worker, condition)
        @worker = worker
        @condition = condition
      end

      def consume_event(event)
        return unless condition_met?(event)

        worker.perform_async(event.class.name, event.data.deep_stringify_keys)

        # We rescue and track any exceptions here because we don't want to
        # impact other subscribers if one is faulty.
        # The method `condition_met?`, since it can run a block, it might encounter
        # a bug. By raising an exception here we could interrupt the publishing
        # process, preventing other subscribers from consuming the event.
      rescue StandardError => e
        Gitlab::ErrorTracking.track_and_raise_for_dev_exception(e, event_class: event.class.name, event_data: event.data)
      end

      private

      def condition_met?(event)
        return true unless condition

        condition.call(event)
      end
    end
  end
end
