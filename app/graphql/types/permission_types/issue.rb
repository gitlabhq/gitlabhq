# frozen_string_literal: true

module Types
  module PermissionTypes
    class Issue < BasePermissionType
      description 'Check permissions for the current user on a issue'
      graphql_name 'IssuePermissions'

      abilities :read_issue, :admin_issue, :update_issue, :reopen_issue,
                :read_design, :create_design, :destroy_design,
                :create_note
    end
  end
end
