# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module HierarchyFinders
        def find_parent_work_item!(resource_parent, work_item_iid)
          parent_work_item = find_work_item_by_iid(resource_parent, work_item_iid)

          return parent_work_item if parent_work_item

          not_found!('Work Item')
        end

        def find_child_work_item!(child_id)
          child_work_item = ::WorkItem.find_by_id(child_id)

          return child_work_item if child_work_item

          # This message matches similar error message from WorkItems::ParentLinks::BaseService.
          # This makes the error message consistent with the service layer error message format.
          render_api_error!('No matching work item found. Make sure that you are adding a valid work item ID.', 404)
        end

        def resolve_namespace_resource_parent!(resource_parent_id)
          namespace = find_namespace_by_path!(resource_parent_id.to_s, allow_project_namespaces: true)
          not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
          namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace
        end
      end
    end
  end
end
