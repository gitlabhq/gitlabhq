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
          render_child_response(result, child_work_item)
        end

        private

        def execute_attach_child(parent_work_item, child_work_item)
          ::WorkItems::ParentLinks::CreateService
            .new(parent_work_item, current_user, { target_issuable: child_work_item })
            .execute
        end
      end
    end
  end
end
