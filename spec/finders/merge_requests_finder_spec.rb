# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequestsFinder, feature_category: :code_review_workflow do
  context "multiple projects with merge requests" do
    include_context 'MergeRequestsFinder multiple projects with merge requests context'

    shared_examples 'scalar or array parameter' do
      let(:values) { merge_requests.pluck(attribute) }
      let(:params) { {} }
      let(:key) { attribute }

      it 'takes scalar values' do
        found = described_class.new(user, params.merge(key => values.first)).execute

        expect(found).to contain_exactly(merge_requests.first)
      end

      it 'takes array values' do
        found = described_class.new(user, params.merge(key => values)).execute

        expect(found).to match_array(merge_requests)
      end
    end

    describe '#execute' do
      it 'filters by scope' do
        params = { scope: 'authored', state: 'opened' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request4, merge_request5)
      end

      it 'filters by project_id' do
        params = { project_id: project1.id, scope: 'authored', state: 'opened' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1)
      end

      context 'filtering by author' do
        subject(:merge_requests) { described_class.new(user, params).execute }

        context 'using OR' do
          let(:params) { { or: { author_username: [merge_request1.author.username, merge_request2.author.username] } } }

          before do
            merge_request1.update!(author: create(:user))
            merge_request2.update!(author: create(:user))
          end

          it 'returns merge requests created by any of the given users' do
            expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
          end
        end

        context 'with nonexistent author ID and MR term using CTE for search' do
          let(:params) { { author_id: 'does-not-exist', search: 'git', attempt_group_search_optimizations: true } }

          it 'returns no results' do
            expect(merge_requests).to be_empty
          end
        end

        context 'filtering by not author ID' do
          let(:params) { { not: { author_id: user2.id } } }

          before do
            merge_request2.update!(author: user2)
            merge_request3.update!(author: user2)
          end

          it 'returns merge requests not created by that user' do
            expect(merge_requests).to contain_exactly(merge_request1, merge_request4, merge_request5)
          end
        end
      end

      it 'filters by projects' do
        params = { projects: [project2.id, project3.id] }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request3, merge_request4)
      end

      context 'filters by commit sha' do
        subject(:merge_requests) { described_class.new(user, commit_sha: commit_sha).execute }

        context 'when commit belongs to the merge request' do
          let(:commit_sha) { merge_request5.merge_request_diff.last_commit_sha }

          it 'filters by commit sha' do
            is_expected.to contain_exactly(merge_request5)
          end
        end

        context 'when commit is a squash commit' do
          before do
            merge_request4.update!(squash_commit_sha: commit_sha)
          end

          let(:commit_sha) { '1234abcd' }

          it 'filters by commit sha' do
            is_expected.to contain_exactly(merge_request4)
          end
        end

        context 'when commit is a merge commit' do
          before do
            merge_request4.update!(merge_commit_sha: commit_sha)
          end

          let(:commit_sha) { '1234dcba' }

          it 'filters by commit sha' do
            is_expected.to contain_exactly(merge_request4)
          end
        end
      end

      context 'filters by merged_at date' do
        before do
          merge_request1.metrics.update!(merged_at: 5.days.ago)
          merge_request2.metrics.update!(merged_at: 10.days.ago)
        end

        describe 'merged_after' do
          subject { described_class.new(user, merged_after: 6.days.ago).execute }

          it { is_expected.to eq([merge_request1]) }
        end

        describe 'merged_before' do
          subject { described_class.new(user, merged_before: 6.days.ago).execute }

          it { is_expected.to eq([merge_request2]) }
        end

        describe 'when both merged_after and merged_before is given' do
          subject { described_class.new(user, merged_after: 15.days.ago, merged_before: 6.days.ago).execute }

          it { is_expected.to eq([merge_request2]) }
        end

        context 'when project_id is given' do
          subject(:query) { described_class.new(user, merged_after: 15.days.ago, merged_before: 6.days.ago, project_id: merge_request2.project).execute }

          it { is_expected.to eq([merge_request2]) }

          it 'queries merge_request_metrics.target_project_id table' do
            expect(query.to_sql).to include(%("merge_request_metrics"."target_project_id" = #{merge_request2.target_project_id}))
          end
        end
      end

      context 'merge_user filtering' do
        before do
          merge_request1.update!(state_id: MergeRequest.available_states[:merged])
          merge_request1.metrics.update!(merged_by_id: user.id)
          merge_request2.update!(state_id: MergeRequest.available_states[:merged])
          merge_request2.metrics.update!(merged_by_id: user.id)
          merge_request3.update!(state_id: MergeRequest.available_states[:merged])
          merge_request3.metrics.update!(merged_by_id: user2.id)
          merge_request4.update!(state_id: MergeRequest.available_states[:merged])
          merge_request4.metrics.update!(merged_by_id: user2.id)
        end

        subject { described_class.new(user, params).execute }

        describe 'by merge_user_id' do
          let(:params) { { merge_user_id: user.id } }
          let(:expected_mr) { [merge_request1, merge_request2] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        describe 'by merge_user_username' do
          let(:params) { { merge_user_username: user.username } }
          let(:expected_mr) { [merge_request1, merge_request2] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        describe 'by merge_user_id with unknown user id' do
          let(:params) { { merge_user_id: 99999 } }

          it { is_expected.to be_empty }
        end

        describe 'by merge_user_username with unknown user name' do
          let(:params) { { merge_user_username: 'does-not-exist' } }

          it { is_expected.to be_empty }
        end
      end

      context 'filtering by group' do
        it 'includes all merge requests when user has access excluding merge requests from projects the user does not have access to' do
          private_project = allow_gitaly_n_plus_1 { create(:project, :private, group: group) }
          private_project.add_guest(user)
          create(:merge_request, :simple, author: user, source_project: private_project, target_project: private_project)
          params = { group_id: group.id }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
        end

        it 'filters by group including subgroups' do
          params = { group_id: group.id, include_subgroups: true }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request5)
        end

        it 'filters by group projects including subgroups' do
          # project3 is not in the group, so it should not return merge_request4
          projects = [project3.id, project4.id]
          params = { group_id: group.id, include_subgroups: true, projects: projects }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request5)
        end
      end

      it 'filters by non_archived' do
        params = { non_archived: true }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request5)
      end

      describe ':iid parameter' do
        it_behaves_like 'scalar or array parameter' do
          let(:params) { { project_id: project1.id } }
          let(:merge_requests) { [merge_request1, merge_request2] }
          let(:key) { :iids }
          let(:attribute) { :iid }
        end
      end

      [:source_branch, :target_branch].each do |param|
        describe "#{param} parameter" do
          let(:merge_requests) { create_list(:merge_request, 2, :unique_branches, source_project: project4, target_project: project4, author: user) }
          let(:attribute) { param }

          it_behaves_like 'scalar or array parameter'
        end
      end

      describe ':label_name parameter' do
        let_it_be(:common_labels) { create_list(:label, 3) }
        let_it_be(:distinct_labels) { create_list(:label, 3) }
        let_it_be(:merge_requests) do
          common_attrs = {
            source_project: project1, target_project: project1, author: user
          }
          distinct_labels.map do |label|
            labels = [label, *common_labels]
            create(:labeled_merge_request, :closed, labels: labels, **common_attrs)
          end
        end

        def find(label_name)
          described_class.new(user, label_name: label_name).execute
        end

        it 'accepts a single label' do
          found = find(distinct_labels.first.title)
          common = find(common_labels.first.title)

          expect(found).to contain_exactly(merge_requests.first)
          expect(common).to match_array(merge_requests)
        end

        it 'accepts an array of labels, all of which must match' do
          all_distinct = find(distinct_labels.pluck(:title))
          all_common = find(common_labels.pluck(:title))

          expect(all_distinct).to be_empty
          expect(all_common).to match_array(merge_requests)
        end
      end

      it 'filters by source project id' do
        params = { source_project_id: merge_request2.source_project_id }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3)
      end

      context 'filter by state event source' do
        let(:params) { { merged_without_event_source: true } }

        before do
          create(:resource_state_event, merge_request: merge_request1, state: :merged)
        end

        it 'filters by resource_state_event' do
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1)
        end
      end

      it 'filters by state' do
        params = { state: 'locked' }

        merge_requests = described_class.new(user, params).execute

        expect(merge_requests).to contain_exactly(merge_request3)
      end

      describe 'draft state' do
        shared_examples 'draft MRs filtering' do |draft_param_key, draft_param_value, title_prefix, draft_only|
          it "filters by #{draft_param_key} => #{draft_param_value}" do
            merge_request1.reload.update!(title: "#{title_prefix} #{merge_request1.title}")

            params = { draft_param_key => draft_param_value }

            merge_requests = described_class.new(user, params).execute

            if draft_only
              expect(merge_requests).to contain_exactly(merge_request1, merge_request4, merge_request5)
            else
              expect(merge_requests).to contain_exactly(merge_request2, merge_request3)
            end
          end
        end

        {
          draft: ["Draft:", "Draft -", "[Draft]", "(Draft)"]
        }.each do |draft_param_key, title_prefixes|
          title_prefixes.each do |title_prefix|
            it_behaves_like 'draft MRs filtering', draft_param_key, 1, title_prefix, true
            it_behaves_like 'draft MRs filtering', draft_param_key, '1', title_prefix, true
            it_behaves_like 'draft MRs filtering', draft_param_key, true, title_prefix, true
            it_behaves_like 'draft MRs filtering', draft_param_key, 'true', title_prefix, true
            it_behaves_like 'draft MRs filtering', draft_param_key, 'yes', title_prefix, true

            it_behaves_like 'draft MRs filtering', draft_param_key, 0, title_prefix, false
            it_behaves_like 'draft MRs filtering', draft_param_key, '0', title_prefix, false
            it_behaves_like 'draft MRs filtering', draft_param_key, false, title_prefix, false
            it_behaves_like 'draft MRs filtering', draft_param_key, 'false', title_prefix, false
            it_behaves_like 'draft MRs filtering', draft_param_key, 'no', title_prefix, false
          end

          it "returns all items if no valid #{draft_param_key} param exists" do
            params = { draft_param_key => '' }

            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(
              merge_request1, merge_request2, merge_request3, merge_request4, merge_request5
            )
          end
        end
      end

      context 'filter by deployment' do
        let_it_be(:project_with_repo) { create(:project, :repository) }

        it 'returns the relevant merge requests' do
          deployment1 = create(
            :deployment,
            project: project_with_repo,
            sha: project_with_repo.commit.id
          )
          deployment2 = create(
            :deployment,
            project: project_with_repo,
            sha: project_with_repo.commit.id
          )
          deployment1.link_merge_requests(MergeRequest.where(id: [merge_request1.id, merge_request2.id]))
          deployment2.link_merge_requests(MergeRequest.where(id: merge_request3.id))

          params = { deployment_id: deployment1.id }
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
        end

        context 'when a deployment does not contain any merge requests' do
          it 'returns an empty result' do
            params = { deployment_id: create(:deployment, project: project_with_repo, sha: project_with_repo.commit.sha).id }
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to be_empty
          end
        end
      end

      context 'filter by blob path' do
        let(:params) { { project_id: project_id, blob_path: blob_path } }

        let_it_be(:merge_request) { create(:merge_request, :opened, source_project: project1, target_project: project1, source_branch: 'feature', target_branch: 'master') }
        let_it_be(:merge_request_diff) { create(:merge_request_diff, merge_request: merge_request) }
        let_it_be(:merge_request_diff_file) { create(:merge_request_diff_file, merge_request_diff: merge_request_diff) }

        let(:project_id) { project1 }
        let(:target_branch) { merge_request.target_branch }
        let(:blob_path) { merge_request_diff_file.old_path }

        it 'returns merge requests with blobs by requested path' do
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request)
        end

        context 'when blob path is not found' do
          let(:blob_path) { 'unknown' }

          it 'does not return merge requests' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to be_empty
          end
        end

        context 'when project_id is not set' do
          let(:project_id) { nil }

          it 'does not return merge requests' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to be_empty
          end
        end
      end

      describe '.scalar_params' do
        it 'contains scalar params related to merge requests' do
          scalar_params = described_class.scalar_params

          expect(scalar_params).to include(:wip, :draft, :assignee_id)
        end
      end

      context 'assignee filtering' do
        let_it_be(:user3) { create(:user) }

        let(:issuables) { described_class.new(user, params).execute }

        it_behaves_like 'assignee ID filter' do
          let(:params) { { assignee_id: user.id } }
          let(:expected_issuables) { [merge_request1, merge_request2] }
        end

        it_behaves_like 'assignee NOT ID filter' do
          let(:params) { { not: { assignee_id: user.id } } }
          let(:expected_issuables) { [merge_request3, merge_request4, merge_request5] }
        end

        it_behaves_like 'assignee username filter' do
          before do
            project2.add_developer(user3)
            merge_request3.assignees = [user2, user3]
          end

          let(:params) { { assignee_username: [user2.username, user3.username] } }
          let(:expected_issuables) { [merge_request3] }
        end

        it_behaves_like 'assignee NOT username filter' do
          before do
            merge_request2.assignees = [user2]
          end

          let(:params) { { not: { assignee_username: [user.username, user2.username] } } }
          let(:expected_issuables) { [merge_request4, merge_request5] }
        end

        it_behaves_like 'no assignee filter' do
          let(:expected_issuables) { [merge_request4, merge_request5] }
        end

        it_behaves_like 'any assignee filter' do
          let(:expected_issuables) { [merge_request1, merge_request2, merge_request3] }
        end
      end

      context 'reviewer filtering' do
        subject { described_class.new(user, params).execute }

        context 'by reviewer_id' do
          let(:params) { { reviewer_id: user2.id } }
          let(:expected_mr) { [merge_request1, merge_request2] }

          it { is_expected.to contain_exactly(*expected_mr) }

          context 'with reviewer state' do
            let(:params) { { reviewer_id: user2.id, review_state: 'requested_changes' } }
            let(:expected_mr) { [merge_request1] }

            before do
              merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
            end

            it { is_expected.to contain_exactly(*expected_mr) }
          end
        end

        context 'by NOT reviewer_id' do
          let(:params) { { not: { reviewer_id: user2.id } } }
          let(:expected_mr) { [merge_request3, merge_request4, merge_request5] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        context 'by reviewer_username' do
          let(:params) { { reviewer_username: user2.username } }
          let(:expected_mr) { [merge_request1, merge_request2] }

          it { is_expected.to contain_exactly(*expected_mr) }

          context 'with review state' do
            let(:params) { { reviewer_username: user2.username, review_state: 'requested_changes' } }
            let(:expected_mr) { [merge_request1] }

            before do
              merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
            end

            it { is_expected.to contain_exactly(*expected_mr) }
          end

          context 'with multiple review state' do
            let(:params) { { reviewer_username: user2.username, review_states: %w[requested_changes reviewed] } }
            let(:expected_mr) { [merge_request1, merge_request2] }

            before do
              merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
              merge_request2.merge_request_reviewers.update_all(state: :reviewed)
            end

            it { is_expected.to contain_exactly(*expected_mr) }
          end
        end

        context 'by NOT reviewer_username' do
          let(:params) { { not: { reviewer_username: user2.username } } }
          let(:expected_mr) { [merge_request3, merge_request4, merge_request5] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        context 'by reviewer_id=None' do
          let(:params) { { reviewer_id: 'None' } }
          let(:expected_mr) { [merge_request4, merge_request5] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        context 'by reviewer_id=Any' do
          let(:params) { { reviewer_id: 'Any' } }
          let(:expected_mr) { [merge_request1, merge_request2, merge_request3] }

          it { is_expected.to contain_exactly(*expected_mr) }
        end

        context 'by reviewer_id with unknown user' do
          let(:params) { { reviewer_id: 99999 } }

          it { is_expected.to be_empty }
        end

        context 'by NOT reviewer_id with unknown user' do
          let(:params) { { not: { reviewer_id: 99999 } } }

          it { is_expected.to be_empty }
        end
      end

      context 'review state filtering' do
        let(:params) { { review_state: 'requested_changes' } }
        let(:expected_mr) { [merge_request1] }

        subject { described_class.new(user, params).execute }

        before do
          merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
        end

        it { is_expected.to contain_exactly(*expected_mr) }
      end

      context 'multiple review state filtering' do
        let(:params) { { review_states: %w[requested_changes reviewed] } }
        let(:expected_mr) { [merge_request1, merge_request2] }

        subject { described_class.new(user, params).execute }

        before do
          merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
          merge_request2.merge_request_reviewers.update_all(state: :requested_changes)
        end

        it { is_expected.to contain_exactly(*expected_mr) }

        context 'by NOT review_states' do
          let(:params) { { not: { review_states: %w[requested_changes reviewed] } } }
          let(:expected_mr) { [merge_request3] }

          before do
            merge_request2.merge_request_reviewers.update_all(state: :reviewed)
          end

          it { is_expected.to contain_exactly(*expected_mr) }
        end
      end

      context 'assignee or reviewer filtering' do
        let(:dashboard_flag_enabled) { true }
        let(:params) { { assigned_user_id: user.id } }
        let(:expected_mrs) { [merge_request1, merge_request2, merge_request3] }

        subject { described_class.new(user, params).execute }

        before do
          stub_feature_flags(merge_request_dashboard: dashboard_flag_enabled)
        end

        context 'when merge_request_dashboard feature flag is disabled' do
          let(:dashboard_flag_enabled) { false }
          let(:expected_mrs) { [merge_request1, merge_request2, merge_request3, merge_request4, merge_request5] }

          it { is_expected.to contain_exactly(*expected_mrs) }
        end

        it { is_expected.to contain_exactly(*expected_mrs) }
      end

      context 'assignee or reviewer filtering with assigned_review_states' do
        let(:params) { { assigned_user_id: user.id, assigned_review_states: [:reviewed] } }
        let(:expected_mr) { [merge_request1, merge_request3] }

        subject { described_class.new(user, params).execute }

        before do
          stub_feature_flags(merge_request_dashboard: true)

          merge_request1.merge_request_reviewers.update_all(state: :reviewed)
        end

        it { is_expected.to contain_exactly(*expected_mr) }
      end

      context 'assignee or reviewer filtering with reviewer_review_states' do
        let(:params) { { assigned_user_id: user2.id, reviewer_review_states: [:reviewed] } }
        let(:expected_mr) { [merge_request1, merge_request3] }

        subject { described_class.new(user2, params).execute }

        before do
          stub_feature_flags(merge_request_dashboard: true)

          merge_request1.merge_request_reviewers.update_all(state: :reviewed)
        end

        it { is_expected.to contain_exactly(*expected_mr) }
      end

      context 'assignee or reviewer filtering with assigned_review_states and reviewer_review_states' do
        let(:params) { { assigned_user_id: user.id, assigned_review_states: [:requested_changes], reviewer_review_states: [:reviewed] } }
        let(:expected_mr) { [merge_request1, merge_request3] }

        subject { described_class.new(user, params).execute }

        before do
          stub_feature_flags(merge_request_dashboard: true)

          merge_request1.merge_request_reviewers.update_all(state: :requested_changes)
          merge_request3.merge_request_reviewers.update_all(state: :reviewed)
        end

        it { is_expected.to contain_exactly(*expected_mr) }
      end

      context 'filtering by group milestone' do
        let(:group_milestone) { create(:milestone, group: group) }

        before do
          merge_request1.update!(milestone: group_milestone)
          merge_request2.update!(milestone: group_milestone)
        end

        it 'returns merge requests assigned to that group milestone' do
          params = { milestone_title: group_milestone.title }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request1, merge_request2)
        end

        context 'using NOT' do
          let(:params) { { not: { milestone_title: group_milestone.title } } }

          it 'returns MRs not assigned to that group milestone' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request3, merge_request4, merge_request5)
          end
        end
      end

      context 'filtering by approved' do
        before do
          create(:approval, merge_request: merge_request3, user: user2)
        end

        context 'when flag `mr_approved_filter` is disabled' do
          before do
            stub_feature_flags(mr_approved_filter: false)
          end

          it 'for approved' do
            merge_requests = described_class.new(user, { approved: true }).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request4, merge_request5)
          end

          it 'for not approved' do
            merge_requests = described_class.new(user, { approved: false }).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request3, merge_request4, merge_request5)
          end
        end

        context 'when flag `mr_approved_filter` is enabled' do
          before do
            stub_feature_flags(mr_approved_filter: true)
          end

          it 'for approved' do
            merge_requests = described_class.new(user, { approved: true }).execute

            expect(merge_requests).to contain_exactly(merge_request3)
          end

          it 'for not approved' do
            merge_requests = described_class.new(user, { approved: false }).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request4, merge_request5)
          end
        end
      end

      context 'filtering by approved by username' do
        let(:params) { { approved_by_usernames: user2.username } }

        where(:sort) { [nil] + %w[milestone merged_at merged_at_desc closed_at closed_at_desc] }

        before do
          create(:approval, merge_request: merge_request3, user: user2)
        end

        with_them do
          it 'returns merge requests approved by that user' do
            params = { approved_by_usernames: user2.username, sort: sort }
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request3)
          end
        end

        context 'not filter' do
          let(:params) { { not: { approved_by_usernames: user2.username } } }

          it 'returns merge requests not approved by that user' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request4, merge_request5)
          end
        end

        context 'when filtering by author and not approved by' do
          let(:params) { { not: { approved_by_usernames: user2.username }, author_username: user.username } }

          before do
            merge_request4.update!(author: user2)
          end

          it 'returns merge requests authored by user and not approved by user2' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request1, merge_request2, merge_request5)
          end
        end
      end

      context 'filtering by approved by user ID' do
        let(:params) { { approved_by_ids: user2.id } }

        before do
          create(:approval, merge_request: merge_request3, user: user2)
        end

        it 'returns merge requests approved by that user' do
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request3)
        end

        context 'with sorting by milestone' do
          let(:params) { { approved_by_usernames: user2.username, sort: 'milestone' } }

          it 'returns merge requests approved by that user' do
            merge_requests = described_class.new(user, params).execute

            expect(merge_requests).to contain_exactly(merge_request3)
          end
        end
      end

      context 'filtering by created_at/updated_at' do
        let_it_be(:new_project) { create(:project, forked_from_project: project1) }

        let!(:new_merge_request) do
          create(
            :merge_request,
            :simple,
            author: user,
            created_at: 1.week.from_now,
            updated_at: 1.week.from_now,
            source_project: new_project,
            target_project: new_project
          )
        end

        let!(:old_merge_request) do
          create(
            :merge_request,
            :simple,
            author: user,
            source_branch: 'feature_1',
            created_at: 1.week.ago,
            updated_at: 1.week.ago,
            source_project: new_project,
            target_project: new_project
          )
        end

        before_all do
          new_project.add_maintainer(user)
        end

        it 'filters by created_after' do
          params = { project_id: new_project.id, created_after: new_merge_request.created_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(new_merge_request)
        end

        it 'filters by created_before' do
          params = { project_id: new_project.id, created_before: old_merge_request.created_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request)
        end

        it 'filters by created_after and created_before' do
          params = {
            project_id: new_project.id,
            created_after: old_merge_request.created_at,
            created_before: new_merge_request.created_at
          }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request, new_merge_request)
        end

        it 'filters by updated_after' do
          params = { project_id: new_project.id, updated_after: new_merge_request.updated_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(new_merge_request)
        end

        it 'filters by updated_before' do
          params = { project_id: new_project.id, updated_before: old_merge_request.updated_at }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request)
        end

        it 'filters by updated_after and updated_before' do
          params = {
            project_id: new_project.id,
            updated_after: old_merge_request.updated_at,
            updated_before: new_merge_request.updated_at
          }

          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(old_merge_request, new_merge_request)
        end
      end

      context 'filtering by the merge request deployments' do
        let_it_be(:gstg) { create(:environment, project: project4, name: 'gstg') }
        let_it_be(:gprd) { create(:environment, project: project4, name: 'gprd') }

        let_it_be(:mr1) do
          create(
            :merge_request,
            :simple,
            :merged,
            author: user,
            source_project: project4,
            target_project: project4
          )
        end

        let_it_be(:mr2) do
          create(
            :merge_request,
            :simple,
            :merged,
            author: user,
            source_project: project4,
            target_project: project4
          )
        end

        let_it_be(:deploy1) do
          create(
            :deployment,
            :success,
            deployable: nil,
            environment: gstg,
            project: project4,
            sha: mr1.diff_head_sha,
            finished_at: Time.utc(2020, 10, 1, 12, 0)
          )
        end

        let_it_be(:deploy2) do
          create(
            :deployment,
            :success,
            deployable: nil,
            environment: gprd,
            project: project4,
            sha: mr2.diff_head_sha,
            finished_at: Time.utc(2020, 10, 2, 15, 0)
          )
        end

        before_all do
          deploy1.link_merge_requests(MergeRequest.where(id: mr1.id))
          deploy2.link_merge_requests(MergeRequest.where(id: mr2.id))
        end

        it 'filters merge requests deployed to a given environment' do
          mrs = described_class.new(user, environment: 'gstg').execute

          expect(mrs).to eq([mr1])
        end

        it 'filters merge requests deployed before a given date' do
          mrs =
            described_class.new(user, deployed_before: '2020-10-02').execute

          expect(mrs).to eq([mr1])
        end

        it 'filters merge requests ignoring empty deployed_before' do
          mrs = described_class.new(user, deployed_before: '').execute

          expect(mrs.size).to eq(7)
        end

        it 'filters merge requests ignoring invalid deployed_before' do
          mrs = described_class.new(user, deployed_before: '2021-99-99').execute

          expect(mrs.size).to eq(7)
        end

        it 'filters merge requests deployed after a given date' do
          mrs = described_class
            .new(user, deployed_after: '2020-10-01 12:00')
            .execute

          expect(mrs).to eq([mr2])
        end

        it 'filters merge requests ignoring empty deployed_after' do
          mrs = described_class.new(user, deployed_after: '').execute

          expect(mrs.size).to eq(7)
        end

        it 'filters merge requests ignoring invalid deployed_after' do
          mrs = described_class.new(user, deployed_after: '2021-99-99').execute

          expect(mrs.size).to eq(7)
        end
      end

      it 'does not raise any exception with complex filters' do
        # available filters from MergeRequest dashboard UI
        params = {
          project_id: project1.id,
          scope: 'authored',
          state: 'opened',
          author_username: user.username,
          assignee_username: user.username,
          reviewer_username: user.username,
          approver_usernames: [user.username],
          approved_by_usernames: [user.username],
          milestone_title: 'none',
          release_tag: 'none',
          label_names: 'none',
          my_reaction_emoji: 'none',
          draft: 'no',
          sort: 'milestone'
        }

        merge_requests = described_class.new(user, params).execute
        expect { merge_requests.load }.not_to raise_error
      end

      context 'filtering by search text' do
        let!(:merge_request6) { create(:merge_request, source_project: project1, target_project: project1, source_branch: 'tanuki-branch', title: 'tanuki') }

        let(:params) { { project_id: project1.id, search: 'tanuki' } }

        it 'returns matching merge requests' do
          merge_requests = described_class.new(user, params).execute

          expect(merge_requests).to contain_exactly(merge_request6)
        end
      end
    end

    describe '#row_count', :request_store do
      it 'returns the number of rows for the default state' do
        finder = described_class.new(user)

        expect(finder.row_count).to eq(3)
      end

      it 'returns the number of rows for a given state' do
        finder = described_class.new(user, state: 'closed')

        expect(finder.row_count).to eq(1)
      end

      it 'returns -1 if the query times out' do
        finder = described_class.new(user)

        expect_next_instance_of(described_class) do |subfinder|
          expect(subfinder).to receive(:execute).and_raise(ActiveRecord::QueryCanceled)
        end

        expect(finder.row_count).to eq(-1)
      end
    end

    context 'external authorization' do
      it_behaves_like 'a finder with external authorization service' do
        let!(:subject) { create(:merge_request, source_project: project) }
        let(:project_params) { { project_id: project.id } }
      end
    end
  end

  context 'when projects require different access levels for merge requests' do
    let_it_be(:user) { create(:user) }

    let_it_be(:public_project) { create(:project, :public) }
    let_it_be(:internal) { create(:project, :internal) }
    let_it_be(:private_project) { create(:project, :private) }
    let_it_be(:public_with_private_repo) { create(:project, :public, :repository, :repository_private) }
    let_it_be(:internal_with_private_repo) { create(:project, :internal, :repository, :repository_private) }

    let(:merge_requests) { described_class.new(user, {}).execute }

    let!(:mr_public) { create(:merge_request, source_project: public_project) }
    let!(:mr_private) { create(:merge_request, source_project: private_project) }
    let!(:mr_internal) { create(:merge_request, source_project: internal) }
    let!(:mr_private_repo_access) { create(:merge_request, source_project: public_with_private_repo) }
    let!(:mr_internal_private_repo_access) { create(:merge_request, source_project: internal_with_private_repo) }

    context 'with admin user' do
      let_it_be(:user) { create(:user, :admin) }

      context 'when admin mode is enabled', :enable_admin_mode do
        it 'returns all merge requests' do
          expect(merge_requests).to contain_exactly(
            mr_internal_private_repo_access, mr_private_repo_access, mr_internal, mr_private, mr_public
          )
        end
      end

      context 'when admin mode is disabled' do
        it 'returns public and internal merge requests' do
          expect(merge_requests).to contain_exactly(mr_internal, mr_public)
        end
      end
    end

    context 'when project restricts merge requests' do
      let(:non_member) { create(:user) }
      let(:project) { create(:project, :repository, :public, :merge_requests_private) }
      let!(:merge_request) { create(:merge_request, source_project: project) }

      it "returns nothing to to non members" do
        merge_requests = described_class.new(
          non_member,
          project_id: project.id
        ).execute

        expect(merge_requests).to be_empty
      end
    end

    context 'with external user' do
      let(:user) { create(:user, :external) }

      it 'returns only public merge requests' do
        expect(merge_requests).to eq([mr_public])
      end
    end

    context 'with authenticated user' do
      it 'returns public and internal merge requests' do
        expect(merge_requests).to eq([mr_internal, mr_public])
      end

      context 'being added to the private project' do
        context 'as a guest' do
          before do
            private_project.add_guest(user)
          end

          it 'does not return merge requests from the private project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a developer' do
          before do
            private_project.add_developer(user)
          end

          it 'returns merge requests from the private project' do
            expect(merge_requests).to eq([mr_internal, mr_private, mr_public])
          end
        end
      end

      context 'being added to the public project with private repo access' do
        context 'as a guest' do
          before do
            public_with_private_repo.add_guest(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a reporter' do
          before do
            public_with_private_repo.add_reporter(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_private_repo_access, mr_internal, mr_public])
          end
        end
      end

      context 'being added to the internal project with private repo access' do
        context 'as a guest' do
          before do
            internal_with_private_repo.add_guest(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal, mr_public])
          end
        end

        context 'as a reporter' do
          before do
            internal_with_private_repo.add_reporter(user)
          end

          it 'returns merge requests from the project' do
            expect(merge_requests).to eq([mr_internal_private_repo_access, mr_internal, mr_public])
          end
        end
      end
    end

    describe '#count_by_state' do
      let_it_be(:user) { create(:user) }
      let_it_be(:project) { create(:project, :repository) }
      let_it_be(:labels) { create_list(:label, 2, project: project) }
      let_it_be(:merge_requests) { create_list(:merge_request, 4, :unique_branches, author: user, target_project: project, source_project: project, labels: labels) }

      before_all do
        project.add_developer(user)
      end

      context 'when filtering by multiple labels' do
        it 'returns the correnct counts' do
          counts = described_class.new(user, { label_name: labels.map(&:name) }).count_by_state

          expect(counts[:all]).to eq(merge_requests.size)
        end
      end

      context 'when filtering by approved_by_usernames' do
        before do
          merge_requests.each { |mr| mr.approved_by_users << user }
        end

        it 'returns the correnct counts' do
          counts = described_class.new(user, { approved_by_usernames: [user.username] }).count_by_state

          expect(counts[:all]).to eq(merge_requests.size)
        end
      end
    end
  end

  context 'when the author of a merge request is banned', feature_category: :insider_threat do
    let_it_be(:user) { create(:user) }
    let_it_be(:banned_user) { create(:user, :banned) }
    let_it_be(:project) { create(:project, :public) }
    let_it_be(:banned_merge_request) { create(:merge_request, author: banned_user, source_project: project) }

    subject { described_class.new(user).execute }

    it { is_expected.not_to include(banned_merge_request) }

    context 'when the user is an admin', :enable_admin_mode do
      let_it_be(:user) { create(:user, :admin) }

      it { is_expected.to include(banned_merge_request) }
    end

    context 'when the `hide_merge_requests_from_banned_users` feature flag is disabled' do
      before do
        stub_feature_flags(hide_merge_requests_from_banned_users: false)
      end

      it { is_expected.to include(banned_merge_request) }
    end
  end
end
