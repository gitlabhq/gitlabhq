# frozen_string_literal: true

module Gitlab
  module Issuable
    module Clone
      class AttributesRewriter
        attr_reader :current_user, :original_entity, :target_parent

        def initialize(current_user, original_entity, target_parent)
          raise ArgumentError, 'target_parent cannot be nil' if target_parent.nil?

          @current_user = current_user
          @original_entity = original_entity
          @target_parent = target_parent
        end

        def execute(include_milestone: true)
          attributes = { label_ids: cloneable_labels.pluck_primary_key }

          if include_milestone
            milestone = matching_milestone(original_entity.milestone&.title)
            attributes[:milestone_id] = milestone.id if milestone.present?
          end

          attributes
        end

        private

        def cloneable_labels
          params = {
            project_id: project&.id,
            group_id: group&.id,
            title: original_entity.labels.select(:title),
            include_ancestor_groups: true
          }

          params[:only_group_labels] = true if target_parent.is_a?(Group)

          LabelsFinder.new(current_user, params).execute
        end

        def matching_milestone(title)
          return if title.blank?

          params = { title: title, project_ids: project&.id, group_ids: group&.id }

          milestones = MilestonesFinder.new(params).execute
          milestones.first
        end

        def project
          target_parent if target_parent.is_a?(Project)
        end

        def group
          if target_parent.is_a?(Group)
            target_parent
          elsif target_parent&.group && current_user.can?(:read_group, target_parent.group)
            target_parent.group
          end
        end
      end
    end
  end
end
