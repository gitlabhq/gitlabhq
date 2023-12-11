# frozen_string_literal: true

module Gitlab
  module EventStore
    class Store
      attr_reader :subscriptions

      def initialize
        @subscriptions = Hash.new { |h, k| h[k] = [] }

        yield(self) if block_given?

        # freeze the subscriptions as safety measure to avoid further
        # subcriptions after initialization.
        lock!
      end

      def subscribe(worker, to:, if: nil, delay: nil, group_size: nil)
        condition = binding.local_variable_get('if')

        Array(to).each do |event|
          validate_subscription!(worker, event)
          subscriptions[event] << Gitlab::EventStore::Subscription.new(worker, condition, delay, group_size)
        end
      end

      def publish(event)
        unless event.is_a?(Event)
          raise InvalidEvent, "Event being published is not an instance of Gitlab::EventStore::Event: got #{event.inspect}"
        end

        subscriptions.fetch(event.class, []).each do |subscription|
          subscription.consume_event(event)
        end
      end

      def publish_group(events)
        event_class = events.first.class

        unless events.all? { |e| e.class < Event && e.instance_of?(event_class) }
          raise InvalidEvent, "Not all events being published are valid"
        end

        subscriptions.fetch(event_class, []).each do |subscription|
          subscription.consume_events(events)
        end
      end

      private

      def lock!
        @subscriptions.freeze
      end

      def validate_subscription!(subscriber, event_class)
        unless event_class < Event
          raise InvalidEvent, "Event being subscribed to is not a subclass of Gitlab::EventStore::Event: got #{event_class}"
        end

        unless subscriber.respond_to?(:perform_async)
          raise InvalidSubscriber, "Subscriber is not an ApplicationWorker: got #{subscriber}"
        end
      end
    end
  end
end
