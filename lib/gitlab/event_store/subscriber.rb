# frozen_string_literal: true

# This module should be included in order to turn an ApplicationWorker
# into a Subscriber.
# This module overrides the `perform` method and provides a better and
# safer interface for handling events via `handle_event` method.
#
# @example:
#   class SomeEventSubscriber
#     include Gitlab::EventStore::Subscriber
#
#     def handle_event(event)
#       # ...
#     end
#   end

module Gitlab
  module EventStore
    module Subscriber
      extend ActiveSupport::Concern

      included do
        include ApplicationWorker

        loggable_arguments 0, 1
        idempotent!
      end

      def perform(event_type, data)
        raise InvalidEvent, event_type unless self.class.const_defined?(event_type)

        event_type_class = event_type.constantize

        Array.wrap(data).each do |single_event_data|
          handle_event(construct_event(event_type_class, single_event_data))
        end
      end

      def handle_event(event)
        raise NotImplementedError, 'you must implement this methods in order to handle events'
      end

      private

      def construct_event(event_type, event_data)
        event_type.new(data: event_data)
      end
    end
  end
end
