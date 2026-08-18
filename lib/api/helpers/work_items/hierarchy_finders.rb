# frozen_string_literal: true

module API
  module Helpers
    module WorkItems
      module HierarchyFinders
        # Every "child not found" path on these endpoints returns the same message so callers can't
        # tell "this work item does not exist" apart from "it exists but you can't see/admin it".
        CHILD_NOT_FOUND_MESSAGE = 'No matching work item found. Make sure that you are adding a valid work item ID.'

        def find_parent_work_item!(resource_parent, work_item_iid)
          parent_work_item = find_work_item_by_iid(resource_parent, work_item_iid)

          return parent_work_item if parent_work_item

          not_found!('Work Item')
        end

        def find_child_work_item!(child_id)
          child_work_item = ::WorkItem.find_by_id(child_id)

          return child_work_item if child_work_item

          render_api_error!(CHILD_NOT_FOUND_MESSAGE, 404)
        end

        def resolve_namespace_resource_parent!(resource_parent_id)
          namespace = find_namespace_by_path!(resource_parent_id.to_s, allow_project_namespaces: true)
          not_found!('Namespace') if namespace.is_a?(::Namespaces::UserNamespace)
          namespace.is_a?(::Namespaces::ProjectNamespace) ? namespace.project : namespace
        end

        def find_parent_link!(parent_work_item, child_work_item)
          ::WorkItems::ParentLink
            .for_parents(parent_work_item.id)
            .for_children(child_work_item.id)
            .first || render_api_error!(CHILD_NOT_FOUND_MESSAGE, 404)
        end
      end
    end
  end
end
