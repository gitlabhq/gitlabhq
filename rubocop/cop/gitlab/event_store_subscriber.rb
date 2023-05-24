# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Cop that checks the implementation of Gitlab::EventStore::Subscriber
      #
      # A worker that implements Gitlab::EventStore::Subscriber
      # must implement the method #handle_event(event) and
      # must not override the method #perform(*args)
      #
      #  # bad
      #  class MySubscriber
      #    include Gitlab::EventStore::Subscriber
      #
      #    def perform(*args)
      #    end
      #  end
      #
      #  # bad
      #  class MySubscriber
      #    include Gitlab::EventStore::Subscriber
      #  end
      #
      #  # good
      #  class MySubscriber
      #    include Gitlab::EventStore::Subscriber
      #
      #    def handle_event(event)
      #    end
      #  end
      #
      class EventStoreSubscriber < RuboCop::Cop::Base
        SUBSCRIBER_MODULE_NAME = 'Gitlab::EventStore::Subscriber'
        FORBID_PERFORM_OVERRIDE = "Do not override `perform` in a `#{SUBSCRIBER_MODULE_NAME}`.".freeze
        REQUIRE_HANDLE_EVENT = "A `#{SUBSCRIBER_MODULE_NAME}` must implement `#handle_event(event)`.".freeze

        def_node_matcher :includes_subscriber?, <<~PATTERN
          (send nil? :include (const (const (const nil? :Gitlab) :EventStore) :Subscriber))
        PATTERN

        def on_send(node)
          return unless includes_subscriber?(node)

          self.is_subscriber ||= true
          self.include_subscriber_node ||= node
        end

        def on_def(node)
          if is_subscriber && node.method_name == :perform
            add_offense(node, message: FORBID_PERFORM_OVERRIDE)
          end

          self.implements_handle_event ||= true if node.method_name == :handle_event
        end

        def on_investigation_end
          super

          if is_subscriber && !implements_handle_event
            add_offense(include_subscriber_node, message: REQUIRE_HANDLE_EVENT)
          end
        end

        private

        attr_accessor :is_subscriber, :include_subscriber_node, :implements_handle_event
      end
    end
  end
end
