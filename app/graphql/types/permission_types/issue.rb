# frozen_string_literal: true

module Types
  module PermissionTypes
    class Issue < BasePermissionType
      graphql_name 'IssuePermissions'
      description 'Check permissions for the current user on a issue'

      abilities :read_issue, :admin_issue, :update_issue, :reopen_issue,
        :read_design, :create_design, :destroy_design,
        :create_note, :update_design, :move_design, :move_issue, :clone_issue,
        :admin_issue_relation
    end
  end
end
