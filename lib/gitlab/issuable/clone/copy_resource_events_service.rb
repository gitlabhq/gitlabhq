# frozen_string_literal: true

module Gitlab
  module Issuable
    module Clone
      class CopyResourceEventsService
        attr_reader :current_user, :original_entity, :new_entity

        def initialize(current_user, original_entity, new_entity)
          @current_user = current_user
          @original_entity = original_entity
          @new_entity = new_entity
        end

        def execute
          copy_resource_label_events
          copy_resource_milestone_events
          copy_resource_state_events
        end

        private

        def namespace_id_for_new_entity(new_entity)
          Gitlab::Issuable::NamespaceGetter.new(new_entity, excluded_issuable_types: [MergeRequest]).namespace_id
        end

        def copy_resource_label_events
          new_namespace_id = namespace_id_for_new_entity(new_entity)

          copy_events(ResourceLabelEvent.table_name, original_entity.resource_label_events) do |event|
            event.attributes
              .except(*(blocked_resource_event_attributes + %w[reference reference_html]))
              .merge(
                entity_key => new_entity.id,
                'action' => ResourceLabelEvent.actions[event.action],
                'namespace_id' => new_namespace_id
              )
          end
        end

        def copy_resource_milestone_events
          return unless milestone_events_supported?

          copy_events(ResourceMilestoneEvent.table_name, original_entity.resource_milestone_events) do |event|
            event_attributes_with_milestone(event, event.milestone_id)
          end
        end

        def copy_resource_state_events
          return unless state_events_supported?

          new_namespace_id = namespace_id_for_new_entity(new_entity)

          copy_events(ResourceStateEvent.table_name, original_entity.resource_state_events) do |event|
            event.attributes
              .except(*blocked_resource_event_attributes)
              .merge(
                entity_key => new_entity.id,
                'state' => ResourceStateEvent.states[event.state],
                'namespace_id' => new_namespace_id
              )
          end
        end

        # Overriden on EE::Gitlab::Issuable::Clone::CopyResourceEventsService
        # These values should never be copied to the new entity. This service should always set a new appropriate
        # value that references the new target.
        def blocked_resource_event_attributes
          %w[id issue_id merge_request_id]
        end

        def event_attributes_with_milestone(event, milestone_id)
          event.attributes
            .except('id')
            .merge(entity_key => new_entity.id,
              'milestone_id' => milestone_id,
              'action' => ResourceMilestoneEvent.actions[event.action],
              'state' => ResourceMilestoneEvent.states[event.state],
              'namespace_id' => new_entity.namespace_id)
        end

        def copy_events(table_name, events_to_copy)
          events_to_copy.find_in_batches do |batch|
            events = batch.filter_map do |event|
              yield(event)
            end

            # A cloned resource is not imported from another project
            events.each do |event|
              event['imported_from'] = ::Import::HasImportSource::IMPORT_SOURCES[:none] if event['imported_from']
            end

            ApplicationRecord.legacy_bulk_insert(table_name, events) # rubocop:disable Gitlab/BulkInsert
          end
        end

        def entity_key
          new_entity.class.base_class.name.underscore.foreign_key
        end

        def milestone_events_supported?
          both_respond_to?(:resource_milestone_events)
        end

        def state_events_supported?
          both_respond_to?(:resource_state_events)
        end

        def both_respond_to?(method)
          original_entity.respond_to?(method) &&
            new_entity.respond_to?(method)
        end
      end
    end
  end
end

Gitlab::Issuable::Clone::CopyResourceEventsService.prepend_mod
