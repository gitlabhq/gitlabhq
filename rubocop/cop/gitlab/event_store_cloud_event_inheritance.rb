# frozen_string_literal: true

module RuboCop
  module Cop
    module Gitlab
      # Forbids direct inheritance from `Gitlab::EventStore::Event`.
      # New event classes should inherit from `Gitlab::EventStore::CloudEvent`
      # (or a descendant) instead.
      #
      # @example
      #   # bad
      #   class MyEvent < Gitlab::EventStore::Event
      #     def schema
      #       { 'type' => 'object' }
      #     end
      #   end
      #
      #   # bad
      #   class MyEvent < ::Gitlab::EventStore::Event
      #   end
      #
      #   # good
      #   class MyEvent < Gitlab::EventStore::CloudEvent
      #     event_category :my_domain
      #     event_type :my_event
      #
      #     def data_schema
      #       { 'type' => 'object' }
      #     end
      #   end
      #
      #   # good
      #   class MyEvent < ::Gitlab::EventStore::CloudEvent
      #   end
      class EventStoreCloudEventInheritance < RuboCop::Cop::Base
        MSG = 'Inherit from `Gitlab::EventStore::CloudEvent` (or a descendant) instead of ' \
          '`Gitlab::EventStore::Event`. ' \
          'All events must comply with the CloudEvents spec. ' \
          'See https://docs.gitlab.com/ee/development/eventstore/'

        # @!method inherits_from_event_store_event?(node)
        def_node_matcher :inherits_from_event_store_event?, <<~PATTERN
          (class _ (const (const (const {nil? cbase} :Gitlab) :EventStore) :Event) ...)
        PATTERN

        def on_class(node)
          return unless inherits_from_event_store_event?(node)

          add_offense(node.parent_class)
        end
      end
    end
  end
end
