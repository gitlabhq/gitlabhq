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

        def copy_resource_label_events
          copy_events(ResourceLabelEvent.table_name, original_entity.resource_label_events) do |event|
            event.attributes
              .except('id', 'reference', 'reference_html')
              .merge(entity_key => new_entity.id, 'action' => ResourceLabelEvent.actions[event.action])
          end
        end

        def copy_resource_milestone_events
          return unless milestone_events_supported?

          copy_events(ResourceMilestoneEvent.table_name, original_entity.resource_milestone_events) do |event|
            if event.remove?
              event_attributes_with_milestone(event, nil)
            else
              destination_milestone = matching_milestone(event.milestone_title)

              event_attributes_with_milestone(event, destination_milestone) if destination_milestone.present?
            end
          end
        end

        def copy_resource_state_events
          return unless state_events_supported?

          copy_events(ResourceStateEvent.table_name, original_entity.resource_state_events) do |event|
            event.attributes
              .except(*blocked_state_event_attributes)
              .merge(entity_key => new_entity.id,
                'state' => ResourceStateEvent.states[event.state])
          end
        end

        # Overriden on EE::Gitlab::Issuable::Clone::CopyResourceEventsService
        def blocked_state_event_attributes
          ['id']
        end

        def event_attributes_with_milestone(event, milestone)
          event.attributes
            .except('id')
            .merge(entity_key => new_entity.id,
              'milestone_id' => milestone&.id,
              'action' => ResourceMilestoneEvent.actions[event.action],
              'state' => ResourceMilestoneEvent.states[event.state])
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

        def matching_milestone(title)
          return if title.blank? || !new_entity.supports_milestone?

          params = { title: title, project_ids: new_entity.project&.id, group_ids: group&.id }

          milestones = MilestonesFinder.new(params).execute
          milestones.first
        end

        def group
          if new_entity.project&.group && current_user.can?(:read_group, new_entity.project.group)
            new_entity.project.group
          end
        end
      end
    end
  end
end

Gitlab::Issuable::Clone::CopyResourceEventsService.prepend_mod
