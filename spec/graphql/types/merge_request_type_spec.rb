# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['MergeRequest'] do
  include GraphqlHelpers

  specify { expect(described_class).to expose_permissions_using(Types::PermissionTypes::MergeRequest) }

  specify { expect(described_class).to require_graphql_authorizations(:read_merge_request) }

  specify { expect(described_class.interfaces).to include(Types::Notes::NoteableInterface) }

  specify { expect(described_class.interfaces).to include(Types::CurrentUserTodos) }

  it 'has the expected fields' do
    expected_fields = %w[
      notes discussions user_permissions id iid title title_html description
      description_html state created_at updated_at source_project target_project
      project project_id source_project_id target_project_id source_branch
      target_branch work_in_progress draft merge_when_pipeline_succeeds diff_head_sha
      merge_commit_sha user_notes_count user_discussions_count should_remove_source_branch
      diff_refs diff_stats diff_stats_summary
      force_remove_source_branch
      merge_status merge_status_enum
      in_progress_merge_commit_sha
      merge_error allow_collaboration should_be_rebased rebase_commit_sha
      rebase_in_progress default_merge_commit_message
      merge_ongoing mergeable_discussions_state web_url
      source_branch_exists target_branch_exists diverged_from_target_branch
      upvotes downvotes head_pipeline pipelines task_completion_status
      milestone assignees reviewers participants subscribed labels discussion_locked time_estimate
      total_time_spent human_time_estimate human_total_time_spent reference author merged_at
      commit_count current_user_todos conflicts auto_merge_enabled approved_by source_branch_protected
      default_merge_commit_message_with_description squash_on_merge available_auto_merge_strategies
      has_ci mergeable commits_without_merge_commits squash security_auto_fix default_squash_commit_message
      auto_merge_strategy merge_user
    ]

    expect(described_class).to have_graphql_fields(*expected_fields).at_least
  end

  describe '#pipelines' do
    subject { described_class.fields['pipelines'] }

    it { is_expected.to have_attributes(max_page_size: 500) }
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

  describe '#diverged_from_target_branch' do
    subject(:execute_query) { GitlabSchema.execute(query, context: { current_user: current_user }).as_json }

    let!(:merge_request) { create(:merge_request, target_project: project, source_project: project) }
    let(:project) { create(:project, :public) }
    let(:current_user) { create :admin }
    let(:query) do
      %(
        {
          project(fullPath: "#{project.full_path}") {
            mergeRequests {
              nodes {
                divergedFromTargetBranch
              }
            }
          }
        }
      )
    end

    it 'delegates the diverged_from_target_branch? call to the merge request entity' do
      expect_next_found_instance_of(MergeRequest) do |instance|
        expect(instance).to receive(:diverged_from_target_branch?)
      end

      execute_query
    end
  end

  describe 'merge_status_enum' do
    let(:type) { GitlabSchema.types['MergeStatus'] }

    it 'has the type MergeStatus' do
      expect(described_class.fields['mergeStatusEnum']).to have_graphql_type(type)
    end

    let_it_be(:project) { create(:project, :public) }

    %i[preparing unchecked cannot_be_merged_recheck checking cannot_be_merged_rechecking can_be_merged cannot_be_merged].each do |state|
      context "when the the DB value is #{state}" do
        let(:merge_request) { create(:merge_request, :unique_branches, source_project: project, merge_status: state.to_s) }

        it 'serializes correctly' do
          value = resolve_field(:merge_status_enum, merge_request)
          value = type.coerce_isolated_result(value)

          expect(value).to eq(merge_request.public_merge_status.upcase)
        end
      end
    end
  end
end
