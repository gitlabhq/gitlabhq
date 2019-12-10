# frozen_string_literal: true

module Types
  module PermissionTypes
    class Project < BasePermissionType
      graphql_name 'ProjectPermissions'

      abilities :change_namespace, :change_visibility_level, :rename_project,
                :remove_project, :archive_project, :remove_fork_project,
                :remove_pages, :read_project, :create_merge_request_in,
                :read_wiki, :read_project_member, :create_issue, :upload_file,
                :read_cycle_analytics, :download_code, :download_wiki_code,
                :fork_project, :read_commit_status,
                :request_access, :create_pipeline, :create_pipeline_schedule,
                :create_merge_request_from, :create_wiki, :push_code,
                :create_deployment, :push_to_delete_protected_branch,
                :admin_wiki, :admin_project, :update_pages,
                :admin_remote_mirror, :create_label, :update_wiki, :destroy_wiki,
                :create_pages, :destroy_pages, :read_pages_content, :admin_operations

      permission_field :create_snippet

      def create_snippet
        Ability.allowed?(context[:current_user], :create_project_snippet, object)
      end
    end
  end
end

Types::PermissionTypes::Project.prepend_if_ee('EE::Types::PermissionTypes::Project')
