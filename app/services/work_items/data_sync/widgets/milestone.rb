# frozen_string_literal: true

module WorkItems
  module DataSync
    module Widgets
      class Milestone < Base
        def before_create
          return unless target_work_item.get_widget(:milestone)
          return if work_item.milestone_id.blank?

          target_work_item.milestone = matching_milestone
        end

        def post_move_cleanup
          work_item.update_column(:milestone_id, nil)
        end

        private

        def matching_milestone
          params = { project_ids: target_work_item.project&.id, group_ids: ancestors }
          milestone = by_id(params)

          return milestone if milestone.present?

          by_title(params)
        end

        def by_id(params)
          return if work_item.milestone_id.blank?

          find_milestone(params.merge(ids: work_item.milestone_id))
        end

        def by_title(params)
          return if work_item.milestone&.title.blank?

          find_milestone(params.merge(title: work_item.milestone&.title))
        end

        def find_milestone(params)
          milestones = MilestonesFinder.new(params).execute
          milestones.first
        end

        def ancestors
          case target_work_item.namespace
          when Group
            target_work_item.namespace.self_and_ancestors
          else
            target_work_item.project.ancestors
          end
        end
      end
    end
  end
end
