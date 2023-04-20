# frozen_string_literal: true

module WorkItems
  module Widgets
    module HierarchyService
      class UpdateService < WorkItems::Widgets::HierarchyService::BaseService
        INVALID_RELATIVE_POSITION_ERROR = 'Relative position is not valid.'
        CHILDREN_REORDERING_ERROR = 'Relative position cannot be combined with childrenIds.'
        UNRELATED_ADJACENT_HIERARCHY_ERROR = 'The adjacent work item\'s parent must match the new parent work item.'
        INVALID_ADJACENT_PARENT_ERROR = 'The adjacent work item\'s parent must match the current parent work item.'

        def before_update_in_transaction(params:)
          return unless params.present?

          if positioning?(params)
            service_response!(handle_positioning(params))
          else
            service_response!(handle_hierarchy_changes(params))
          end
        end

        private

        def handle_positioning(params)
          validate_positioning!(params)

          arguments = {
            target_issuable: work_item,
            adjacent_work_item: params.delete(:adjacent_work_item),
            relative_position: params.delete(:relative_position)
          }
          work_item_parent = params.delete(:parent) || work_item.work_item_parent
          ::WorkItems::ParentLinks::ReorderService.new(work_item_parent, current_user, arguments).execute
        end

        def positioning?(params)
          params[:relative_position].present? || params[:adjacent_work_item].present?
        end

        def error!(message)
          service_response!(error(_(message)))
        end

        def validate_positioning!(params)
          error!(INVALID_RELATIVE_POSITION_ERROR) if incomplete_relative_position?(params)
          error!(CHILDREN_REORDERING_ERROR) if positioning_children?(params)
          error!(UNRELATED_ADJACENT_HIERARCHY_ERROR) if unrelated_adjacent_hierarchy?(params)
          error!(INVALID_ADJACENT_PARENT_ERROR) if invalid_adjacent_parent?(params)
        end

        def positioning_children?(params)
          params.key?(:children)
        end

        def incomplete_relative_position?(params)
          params[:adjacent_work_item].blank? || params[:relative_position].blank?
        end

        def unrelated_adjacent_hierarchy?(params)
          return false if params[:parent].blank?

          params[:parent] != params[:adjacent_work_item].work_item_parent
        end

        def invalid_adjacent_parent?(params)
          return false if params[:parent].present?

          work_item.work_item_parent != params[:adjacent_work_item].work_item_parent
        end
      end
    end
  end
end
