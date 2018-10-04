require 'spec_helper'

describe Types::PermissionTypes::Project do
  it do
    expected_permissions = [
      :change_namespace, :change_visibility_level, :rename_project, :remove_project, :archive_project,
      :remove_fork_project, :remove_pages, :read_project, :create_merge_request_in,
      :read_wiki, :read_project_member, :create_issue,  :upload_file, :read_cycle_analytics,
      :download_code, :download_wiki_code, :fork_project, :create_project_snippet,
      :read_commit_status, :request_access, :create_pipeline, :create_pipeline_schedule,
      :create_merge_request_from, :create_wiki, :push_code, :create_deployment, :push_to_delete_protected_branch,
      :admin_wiki, :admin_project, :update_pages, :admin_remote_mirror, :create_label,
      :update_wiki, :destroy_wiki, :create_pages, :destroy_pages
    ]

    expect(described_class).to have_graphql_fields(expected_permissions)
  end
end
