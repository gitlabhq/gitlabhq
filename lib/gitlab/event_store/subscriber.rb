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

        event = event_type.constantize.new(
          data: data.with_indifferent_access
        )

        handle_event(event)
      end

      def handle_event(event)
        raise NotImplementedError, 'you must implement this methods in order to handle events'
      end
    end
  end
end
