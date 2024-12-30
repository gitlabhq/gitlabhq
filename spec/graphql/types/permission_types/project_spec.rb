# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::PermissionTypes::Project do
  it do
    expected_permissions = [
      :change_namespace, :change_visibility_level, :rename_project, :remove_project, :archive_project,
      :remove_fork_project, :remove_pages, :read_project, :create_merge_request_in,
      :read_wiki, :read_project_member, :create_issue, :upload_file, :read_cycle_analytics,
      :download_code, :download_wiki_code, :fork_project, :create_snippet,
      :read_commit_status, :request_access, :create_pipeline, :create_pipeline_schedule,
      :create_merge_request_from, :create_wiki, :push_code, :create_deployment, :push_to_delete_protected_branch,
      :admin_wiki, :admin_project, :update_pages, :admin_remote_mirror, :create_label,
      :update_wiki, :destroy_wiki, :create_pages, :destroy_pages, :read_pages_content,
      :read_merge_request, :read_design, :create_design, :update_design, :destroy_design, :move_design,
      :read_environment, :view_edit_page
    ]

    expected_permissions.each do |permission|
      expect(described_class).to have_graphql_field(permission)
    end
  end
end
