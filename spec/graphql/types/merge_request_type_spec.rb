require 'spec_helper'

describe GitlabSchema.types['MergeRequest'] do
  it { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }

  it { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  it { expect(described_class.interfaces).to include(Types::Notes::NoteableType.to_graphql) }

  it 'has the expected fields' do
    expected_fields = %w[
      notes discussions user_permissions id iid title title_html description
      description_html state created_at updated_at source_project target_project
      project project_id source_project_id target_project_id source_branch
      target_branch work_in_progress merge_when_pipeline_succeeds diff_head_sha
      merge_commit_sha user_notes_count should_remove_source_branch
      force_remove_source_branch merge_status in_progress_merge_commit_sha
      merge_error allow_collaboration should_be_rebased rebase_commit_sha
      rebase_in_progress merge_commit_message default_merge_commit_message
      merge_ongoing source_branch_exists mergeable_discussions_state web_url
      upvotes downvotes subscribed head_pipeline pipelines task_completion_status
    ]

    is_expected.to have_graphql_fields(*expected_fields)
  end
end
