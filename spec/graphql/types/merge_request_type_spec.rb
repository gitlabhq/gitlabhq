# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequest'] do
  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }

  specify { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  specify { expect(described_class.interfaces).to include(Types::Notes::NoteableType) }

  specify { expect(described_class.interfaces).to include(Types::CurrentUserTodos) }

  it 'has the expected fields' do
    expected_fields = %w[
      notes discussions user_permissions id iid title title_html description
      description_html state created_at updated_at source_project target_project
      project project_id source_project_id target_project_id source_branch
      target_branch work_in_progress merge_when_pipeline_succeeds diff_head_sha
      merge_commit_sha user_notes_count user_discussions_count should_remove_source_branch
      diff_refs diff_stats diff_stats_summary
      force_remove_source_branch merge_status in_progress_merge_commit_sha
      merge_error allow_collaboration should_be_rebased rebase_commit_sha
      rebase_in_progress default_merge_commit_message
      merge_ongoing mergeable_discussions_state web_url
      source_branch_exists target_branch_exists
      upvotes downvotes head_pipeline pipelines task_completion_status
      milestone assignees participants subscribed labels discussion_locked time_estimate
      total_time_spent reference author merged_at commit_count current_user_todos
      conflicts auto_merge_enabled approved_by source_branch_protected
    ]

    if Gitlab.ee?
      expected_fields << 'approved'
      expected_fields << 'approvals_left'
      expected_fields << 'approvals_required'
    end

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#diff_stats_summary' do
    subject { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let(:current_user) { create :admin }
    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            mergeRequests {
              nodes {
                diffStatsSummary {
                  additions, deletions
                }
              }
            }
          }
        }
      )
    end

    let(:project) { create(:project, :public) }
    let(:merge_request) { create(:merge_request, target_project: project, source_project: project) }

    let(:response) { subject.dig('data', 'project', 'mergeRequests', 'nodes').first['diffStatsSummary'] }

    context 'when MR metrics has additions and deletions' do
      before do
        merge_request.metrics.update!(added_lines: 5, removed_lines: 8)
      end

      it 'pulls out data from metrics object' do
        expect(response).to match('additions' => 5, 'deletions' => 8)
      end
    end
  end
end
