# frozen_string_literal: true

module Issuable
  module Clone
    class AttributesRewriter < ::Issuable::Clone::BaseService
      def initialize(current_user, original_entity, new_entity)
        @current_user = current_user
        @original_entity = original_entity
        @new_entity = new_entity
      end

      def execute
        update_attributes = { labels: cloneable_labels }

        milestone = matching_milestone(original_entity.milestone&.title)
        update_attributes[:milestone] = milestone if milestone.present?

        new_entity.update(update_attributes)

        copy_resource_label_events
        copy_resource_milestone_events
        copy_resource_state_events
      end

      private

      def matching_milestone(title)
        return if title.blank? || !new_entity.supports_milestone?

        params = { title: title, project_ids: new_entity.project&.id, group_ids: group&.id }

        milestones = MilestonesFinder.new(params).execute
        milestones.first
      end

      def cloneable_labels
        params = {
          project_id: new_entity.project&.id,
          group_id: group&.id,
          title: original_entity.labels.select(:title),
          include_ancestor_groups: true
        }

        params[:only_group_labels] = true if new_parent.is_a?(Group)

        LabelsFinder.new(current_user, params).execute
      end

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
            matching_destination_milestone = matching_milestone(event.milestone_title)

            event_attributes_with_milestone(event, matching_destination_milestone) if matching_destination_milestone.present?
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

      # Overriden on EE::Issuable::Clone::AttributesRewriter
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
          events = batch.map do |event|
            yield(event)
          end.compact

          Gitlab::Database.bulk_insert(table_name, events) # rubocop:disable Gitlab/BulkInsert
        end
      end

      def entity_key
        new_entity.class.name.underscore.foreign_key
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

Issuable::Clone::AttributesRewriter.prepend_mod_with('Issuable::Clone::AttributesRewriter')
