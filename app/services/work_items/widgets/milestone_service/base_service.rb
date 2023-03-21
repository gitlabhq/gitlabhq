# frozen_string_literal: true

module WorkItems
  module Widgets
    module MilestoneService
      class BaseService < WorkItems::Widgets::BaseService
        private

        def handle_milestone_change(params:)
          return unless params.present? && params.key?(:milestone_id)

          unless has_permission?(:set_work_item_metadata)
            params.delete(:milestone_id)
            return
          end

          if params[:milestone_id].nil?
            work_item.milestone = nil

            return
          end

          resource_group = work_item.project&.group || work_item.namespace
          project_ids = [work_item.project&.id].compact
          milestone = MilestonesFinder.new({
            project_ids: project_ids,
            group_ids: resource_group&.self_and_ancestors&.select(:id),
            ids: [params[:milestone_id]]
          }).execute.first

          if milestone
            work_item.milestone = milestone
          else
            params.delete(:milestone_id)
          end
        end
      end
    end
  end
end
