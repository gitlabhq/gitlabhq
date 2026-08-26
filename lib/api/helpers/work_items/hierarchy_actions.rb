# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module HierarchyActions
        def attach_child_work_item!(resource_parent, work_item_iid, child_id)
          check_work_item_rest_api_feature_flag!

          parent_work_item = find_parent_work_item!(resource_parent, work_item_iid)
          authorize! :update_work_item, parent_work_item

          child_work_item = find_child_work_item!(child_id)

          result = execute_attach_child(parent_work_item, child_work_item)
          render_child_response(result, child_work_item, status_code: :created)
        end

        def detach_child_work_item!(resource_parent, work_item_iid, child_id)
          check_work_item_rest_api_feature_flag!

          parent_work_item = find_parent_work_item!(resource_parent, work_item_iid)
          authorize! :update_work_item, parent_work_item

          child_work_item = find_child_work_item!(child_id)
          parent_link = find_parent_link!(parent_work_item, child_work_item)

          result = execute_detach_child(parent_link)

          if result[:status] == :success
            status :no_content
          elsif result[:http_status] == 404
            render_api_error!(HierarchyFinders::CHILD_NOT_FOUND_MESSAGE, 404)
          else
            render_api_error!(result[:message], result[:http_status] || :unprocessable_entity)
          end
        end

        def reorder_child_work_item!(resource_parent:, work_item_iid:, child_id:, move_before_id:, move_after_id:)
          check_work_item_rest_api_feature_flag!

          parent_work_item = find_parent_work_item!(resource_parent, work_item_iid)
          authorize! :update_work_item, parent_work_item

          child_work_item = find_sibling_work_item!(parent_work_item, child_id)
          adjacent_work_item = find_readable_sibling_work_item!(parent_work_item, move_before_id || move_after_id)

          result = execute_reorder_child(parent_work_item, child_work_item, adjacent_work_item, move_before_id)
          render_child_response(result, child_work_item, status_code: :ok)
        end

        private

        def execute_attach_child(parent_work_item, child_work_item)
          ::WorkItems::ParentLinks::CreateService
            .new(parent_work_item, current_user, { target_issuable: child_work_item })
            .execute
        end

        def execute_detach_child(parent_link)
          ::WorkItems::ParentLinks::DestroyService.new(parent_link, current_user).execute
        end

        def execute_reorder_child(parent_work_item, child_work_item, adjacent_work_item, move_before_id)
          ::WorkItems::ParentLinks::ReorderService
            .new(parent_work_item, current_user, {
              target_issuable: child_work_item,
              adjacent_work_item: adjacent_work_item,
              relative_position: move_before_id ? 'AFTER' : 'BEFORE'
            })
            .execute
        end
      end
    end
  end
end
