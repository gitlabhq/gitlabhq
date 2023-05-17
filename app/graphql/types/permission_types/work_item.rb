# frozen_string_literal: true

module Types
  module PermissionTypes
    class WorkItem < BasePermissionType
      graphql_name 'WorkItemPermissions'
      description 'Check permissions for the current user on a work item'

      abilities :read_work_item, :update_work_item, :delete_work_item,
        :admin_work_item, :admin_parent_link, :set_work_item_metadata
    end
  end
end
