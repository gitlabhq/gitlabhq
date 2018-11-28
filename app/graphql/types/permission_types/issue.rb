# frozen_string_literal: true

module Types
  module PermissionTypes
    class Issue < BasePermissionType
      description 'Check permissions for the current user on a issue'
      graphql_name 'IssuePermissions'

      abilities :read_issue, :admin_issue,
                :update_issue, :create_note,
                :reopen_issue
    end
  end
end
