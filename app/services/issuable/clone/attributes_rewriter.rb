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

        milestone = cloneable_milestone
        update_attributes[:milestone] = milestone if milestone.present?

        new_entity.update(update_attributes)

        copy_resource_label_events
        copy_resource_weight_events
      end

      private

      def cloneable_milestone
        return unless new_entity.supports_milestone?

        title = original_entity.milestone&.title
        return unless title

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
        original_entity.resource_label_events.find_in_batches do |batch|
          events = batch.map do |event|
            entity_key = new_entity.is_a?(Issue) ? 'issue_id' : 'epic_id'
            event.attributes
              .except('id', 'reference', 'reference_html')
              .merge(entity_key => new_entity.id, 'action' => ResourceLabelEvent.actions[event.action])
          end

          Gitlab::Database.bulk_insert(ResourceLabelEvent.table_name, events)
        end
      end

      def copy_resource_weight_events
        return unless original_entity.respond_to?(:resource_weight_events)

        original_entity.resource_weight_events.find_in_batches do |batch|
          events = batch.map do |event|
            event.attributes
              .except('id', 'reference', 'reference_html')
              .merge('issue_id' => new_entity.id)
          end

          Gitlab::Database.bulk_insert(ResourceWeightEvent.table_name, events)
        end
      end

      def entity_key
        new_entity.class.name.parameterize('_').foreign_key
      end
    end
  end
end
