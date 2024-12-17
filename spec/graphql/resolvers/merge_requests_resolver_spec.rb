# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestsResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers
  include SortingHelper
  include MrResolverHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:other_project) { create(:project, :repository) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:common_attrs) { { author: current_user, source_project: project, target_project: project } }
  let_it_be(:merge_request_1) { create(:merge_request, :simple, reviewers: create_list(:user, 2), **common_attrs) }
  let_it_be(:merge_request_2) { create(:merge_request, :rebased, reviewers: [current_user], **common_attrs) }
  let_it_be(:merge_request_3) { create(:merge_request, :unique_branches, assignees: [current_user], **common_attrs) }
  let_it_be(:merge_request_4) { create(:merge_request, :unique_branches, :locked, **common_attrs) }
  let_it_be(:merge_request_5) { create(:merge_request, :simple, :locked, **common_attrs) }
  let_it_be(:merge_request_6) do
    create(:labeled_merge_request, :unique_branches, **common_attrs, labels: create_list(:label, 2, project: project))
  end

  let_it_be(:merge_request_with_milestone) do
    create(:merge_request, :unique_branches, **common_attrs, milestone: milestone)
  end

  let_it_be(:other_merge_request) do
    create(:merge_request, source_project: other_project, target_project: other_project)
  end

  let(:iid_1) { merge_request_1.iid }
  let(:iid_2) { merge_request_2.iid }
  let(:other_iid) { other_merge_request.iid }

  before do
    project.add_developer(current_user)
    other_project.add_developer(current_user)
  end

  describe '#resolve' do
    # One for the initial auth, then MRs, and the load of project and project_feature (for further auth):
    # SELECT MAX("project_authorizations"."access_level") AS maximum_access_level,
    #   "project_authorizations"."user_id" AS project_authorizations_user_id
    #   FROM "project_authorizations"
    #   WHERE "project_authorizations"."project_id" = 2 AND "project_authorizations"."user_id" = 2
    #   GROUP BY "project_authorizations"."user_id"
    # SELECT "merge_requests".* FROM "merge_requests" WHERE "merge_requests"."target_project_id" = 2
    #   AND "merge_requests"."iid" = 1 ORDER BY "merge_requests"."id" DESC
    # SELECT "projects".* FROM "projects" WHERE "projects"."id" = 2
    # SELECT "project_features".* FROM "project_features" WHERE "project_features"."project_id" = 2
    let(:queries_per_project) { 4 }

    context 'without arguments' do
      it 'returns all merge requests' do
        result = resolve_mr(project)

        expect(result).to contain_exactly(
          merge_request_1, merge_request_2, merge_request_3, merge_request_4, merge_request_5,
          merge_request_6, merge_request_with_milestone
        )
      end

      it 'returns only merge requests that the current user can see' do
        result = resolve_mr(project, user: build(:user))

        expect(result).to be_empty
      end
    end

    context 'with iid alone' do
      it 'batch-resolves by target project full path and individual IID', :request_store do
        # 1 query for project_authorizations, and 1 for merge_requests
        result = batch_sync(max_queries: queries_per_project) do
          [iid_1, iid_2].map { |iid| resolve_mr_single(project, iid) }
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2)
      end

      it 'batch-resolves by target project full path and IIDS', :request_store do
        result = batch_sync(max_queries: queries_per_project) do
          resolve_mr(project, iids: [iid_1, iid_2]).to_a
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2)
      end

      it 'batch-resolves by target project full path and IIDS, single or plural', :request_store do
        result = batch_sync(max_queries: queries_per_project) do
          [resolve_mr_single(project, merge_request_3.iid), *resolve_mr(project, iids: [iid_1, iid_2])]
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2, merge_request_3)
      end

      it 'can batch-resolve merge requests from different projects', :request_store do
        # 2 queries for organization_users, 2 for project_authorizations, and 2 for merge_requests
        extra_auth_queries = 2
        results = batch_sync(max_queries: (queries_per_project + extra_auth_queries) * 2) do
          a = resolve_mr(project, iids: [iid_1])
          b = resolve_mr(project, iids: [iid_2])
          c = resolve_mr(other_project, iids: [other_iid])

          [a, b, c].flat_map(&:to_a)
        end

        expect(results).to contain_exactly(merge_request_1, merge_request_2, other_merge_request)
      end

      it 'resolves an unknown iid to be empty' do
        result = batch_sync { resolve_mr_single(project, -1) }

        expect(result).to be_nil
      end

      it 'resolves empty iids to be empty' do
        result = batch_sync { resolve_mr(project, iids: []) }

        expect(result).to be_empty
      end

      it 'resolves an unknown project to be nil when single' do
        result = batch_sync { resolve_mr_single(nil, iid_1) }

        expect(result).to be_nil
      end

      it 'resolves an unknown project to be empty' do
        result = batch_sync { resolve_mr(nil, iids: [iid_1]) }

        expect(result).to be_empty
      end
    end

    context 'with negated author argument' do
      let_it_be(:author) { current_user }
      let_it_be(:different_author_mr) { create(:merge_request, **common_attrs, author: create(:user)) }

      it 'excludes merge requests with given author from selection' do
        result = resolve_mr(project, not: { author_username: author.username })

        expect(result).to contain_exactly(different_author_mr)
      end
    end

    context 'with source branches argument' do
      it 'takes one argument' do
        result = resolve_mr(project, source_branches: [merge_request_3.source_branch])

        expect(result).to contain_exactly(merge_request_3)
      end

      it 'takes more than one argument' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:source_branch)
        result = resolve_mr(project, source_branches: branches)

        expect(result).to match_array(mrs)
      end
    end

    context 'with negated source branches argument' do
      it 'excludes merge requests with given source branches from selection' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:source_branch)
        result = resolve_mr(project, not: { source_branches: branches })

        expect(result).not_to include(*mrs)
      end
    end

    context 'with target branches argument' do
      it 'takes one argument' do
        result = resolve_mr(project, target_branches: [merge_request_3.target_branch])

        expect(result).to contain_exactly(merge_request_3)
      end

      it 'takes more than one argument' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:target_branch)
        result = resolve_mr(project, target_branches: branches)

        expect(result).to match_array(mrs)
      end
    end

    context 'with negated target branches argument' do
      it 'excludes merge requests with given target branches from selection' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:target_branch)
        result = resolve_mr(project, not: { target_branches: branches })

        expect(result).not_to include(merge_request_3, merge_request_4)
        expect(result).to include(merge_request_1, merge_request_2, merge_request_5, merge_request_6)
      end
    end

    context 'with state argument' do
      it 'takes one argument' do
        result = resolve_mr(project, state: 'locked')

        expect(result).to contain_exactly(merge_request_4, merge_request_5)
      end
    end

    context 'with draft argument' do
      before do
        merge_request_4.update!(title: MergeRequest.draft_title(merge_request_4.title))
      end

      context 'with draft: true argument' do
        it 'takes one argument' do
          result = resolve_mr(project, draft: true)

          expect(result).to contain_exactly(merge_request_4)
        end
      end

      context 'with draft: false argument' do
        it 'takes one argument' do
          result = resolve_mr(project, draft: false)

          expect(result).not_to contain_exactly(merge_request_1, merge_request_2, merge_request_3, merge_request_5, merge_request_6)
        end
      end
    end

    context 'with label argument' do
      let_it_be(:label) { merge_request_6.labels.first }
      let_it_be(:with_label) { create(:labeled_merge_request, :closed, labels: [label], **common_attrs) }

      it 'takes one argument' do
        result = resolve_mr(project, labels: [label.title])

        expect(result).to contain_exactly(merge_request_6, with_label)
      end

      it 'takes multiple arguments, with semantics of ALL MUST MATCH' do
        result = resolve_mr(project, labels: merge_request_6.labels.map(&:title))

        expect(result).to contain_exactly(merge_request_6)
      end
    end

    context 'with negated label argument' do
      let_it_be(:label) { merge_request_6.labels.first }
      let_it_be(:with_label) { create(:labeled_merge_request, :closed, labels: [label], **common_attrs) }

      it 'excludes merge requests with given label from selection' do
        result = resolve_mr(project, not: { labels: [label.title] })

        expect(result).not_to include(merge_request_6, with_label)
      end
    end

    context 'with merged_after and merged_before arguments' do
      before do
        merge_request_1.metrics.update!(merged_at: 10.days.ago)
      end

      it 'returns merge requests merged between the given period' do
        result = resolve_mr(project, merged_after: 20.days.ago, merged_before: 5.days.ago)

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'does not return anything' do
        result = resolve_mr(project, merged_after: 2.days.ago)

        expect(result).to be_empty
      end
    end

    context 'with merged_by argument' do
      before_all do
        merge_request_1.metrics.update!(merged_by: other_user)
      end

      context "for matching arguments" do
        it 'returns merge requests merged by user' do
          result = resolve_mr(project, merged_by: other_user.username)

          expect(result).to contain_exactly(merge_request_1)
        end

        it 'does not return anything' do
          result = resolve_mr(project, merged_by: "cool_guy_123")

          expect(result).to be_empty
        end
      end
    end

    context 'with release argument' do
      let_it_be(:release_in_project) { create(:release, :with_milestones, project: merge_request_1.project) }
      let_it_be(:milestone) { release_in_project.milestones.last }

      before_all do
        merge_request_1.update!(milestone: milestone)
      end

      it 'returns merge requests in release' do
        result = resolve_mr(project, release_tag: release_in_project.name)

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'does not return anything' do
        result = resolve_mr(project, release_tag: "8675309.0")

        expect(result).to be_empty
      end

      it 'filters out merge requests with given milestone title' do
        result = resolve_mr(project, not: { release_tag: release_in_project.name })

        expect(result).not_to include(merge_request_1)
      end
    end

    context 'with approved_by argument' do
      let(:username) { other_user.username }

      before_all do
        merge_request_1.approvals.create!(user: other_user)
      end

      it 'returns merge requests approved by user' do
        result = resolve_mr(project, approved_by: [username])

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'does not return anything' do
        result = resolve_mr(project, approved_by: ["cool_guy_123"])

        expect(result).to be_empty
      end

      context 'with negated approved by argument' do
        it 'filters out merge requests with given approved user' do
          result = resolve_mr(project, not: { approved_by: [username] })

          expect(result).not_to include(merge_request_1)
        end
      end
    end

    context 'with my_reaction_emoji argument' do
      before_all do
        merge_request_1.award_emoji.create!(name: "poop", user: current_user)
      end

      it 'returns merge requests with a reaction emoji set by user' do
        result = resolve_mr(project, my_reaction_emoji: "poop")

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'does not return anything' do
        result = resolve_mr(project, my_reaction_emoji: AwardEmoji::THUMBS_UP)

        expect(result).to be_empty
      end

      context 'with negated my_reaction_emoji argument' do
        it 'filters out merge requests with given reaction emoji' do
          result = resolve_mr(project, not: { my_reaction_emoji: "poop" })

          expect(result).not_to include(merge_request_1)
        end
      end
    end

    context 'when filtering by the merge request deployments' do
      let_it_be(:gstg) { create(:environment, project: project, name: 'gstg') }
      let_it_be(:gprd) { create(:environment, project: project, name: 'gprd') }

      let_it_be(:deploy1) do
        create(
          :deployment,
          :success,
          deployable: nil,
          environment: gstg,
          project: project,
          sha: merge_request_1.diff_head_sha,
          finished_at: 10.days.ago
        )
      end

      let_it_be(:deploy2) do
        create(
          :deployment,
          :success,
          deployable: nil,
          environment: gprd,
          project: project,
          sha: merge_request_2.diff_head_sha,
          finished_at: 3.days.ago
        )
      end

      before do
        deploy1.link_merge_requests(MergeRequest.where(id: merge_request_1.id))
        deploy2.link_merge_requests(MergeRequest.where(id: merge_request_2.id))
      end

      context 'with deployed_after and deployed_before arguments' do
        it 'returns merge requests deployed between the given period' do
          result = resolve_mr(project, deployed_after: 20.days.ago, deployed_before: 5.days.ago)

          expect(result).to contain_exactly(merge_request_1)
        end

        it 'does not return anything when there are no merge requests within the given period' do
          result = resolve_mr(project, deployed_after: 2.days.ago)

          expect(result).to be_empty
        end
      end

      context 'with deployment' do
        it 'returns merge request with matching deployment' do
          result = resolve_mr(project, deployment_id: deploy2.id)

          expect(result).to contain_exactly(merge_request_2)
        end
      end
    end

    context 'when filtering by environment' do
      let_it_be(:gstg) { create(:environment, project: project, name: 'gstg') }
      let_it_be(:gprd) { create(:environment, project: project, name: 'gprd') }

      let_it_be(:deploy1) do
        create(
          :deployment,
          :success,
          deployable: nil,
          environment: gstg,
          project: project,
          sha: merge_request_1.diff_head_sha
        )
      end

      before do
        deploy1.link_merge_requests(MergeRequest.where(id: merge_request_1.id))
      end

      it 'returns merge requests for a given environment' do
        result = resolve_mr(project, environment_name: gstg.name)

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'returns an empty list when no merge requests exist in a given environment' do
        result = resolve_mr(project, environment_name: gprd.name)

        expect(result).to be_empty
      end
    end

    context 'with created_after and created_before arguments' do
      before do
        merge_request_1.update!(created_at: 4.days.ago)
      end

      let(:all_mrs) do
        [merge_request_1, merge_request_2, merge_request_3, merge_request_4, merge_request_5, merge_request_6, merge_request_with_milestone]
      end

      it 'returns merge requests created within a given period' do
        result = resolve_mr(project, created_after: 5.days.ago, created_before: 2.days.ago)

        expect(result).to contain_exactly(
          merge_request_1
        )
      end

      it 'returns some values filtered with created_before' do
        result = resolve_mr(project, created_before: 1.day.ago)

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'returns some values filtered with created_after' do
        result = resolve_mr(project, created_after: 3.days.ago)

        expect(result).to match_array(all_mrs - [merge_request_1])
      end

      it 'does not return anything for dates (even in the future) not matching any MRs' do
        result = resolve_mr(project, created_after: 5.days.from_now)

        expect(result).to be_empty
      end

      it 'does not return anything for dates not matching any MRs' do
        result = resolve_mr(project, created_before: 15.days.ago)

        expect(result).to be_empty
      end

      it 'does not return any values for an impossible set' do
        result = resolve_mr(project, created_after: 5.days.ago, created_before: 6.days.ago)

        expect(result).to be_empty
      end
    end

    context 'with milestone argument' do
      it 'filters merge requests by milestone title' do
        result = resolve_mr(project, milestone_title: milestone.title)

        expect(result).to contain_exactly(merge_request_with_milestone)
      end

      it 'does not find anything' do
        result = resolve_mr(project, milestone_title: 'unknown-milestone')

        expect(result).to be_empty
      end
    end

    it_behaves_like 'graphql query for searching issuables' do
      let_it_be(:parent) { project }
      let_it_be(:issuable1) { create(:merge_request, :unique_branches, title: 'Fixed a bug', **common_attrs) }
      let_it_be(:issuable1) { create(:merge_request, :unique_branches, title: 'first created', **common_attrs) }
      let_it_be(:issuable2) { create(:merge_request, :unique_branches, title: 'second created', description: 'text 1', **common_attrs) }
      let_it_be(:issuable3) { create(:merge_request, :unique_branches, title: 'third', description: 'text 2', **common_attrs) }
      let_it_be(:issuable4) { create(:merge_request, :unique_branches, **common_attrs) }

      let_it_be(:finder_class) { MergeRequestsFinder }
      let_it_be(:optimization_param) { :attempt_project_search_optimizations }
    end

    context 'with negated milestone argument' do
      it 'filters out merge requests with given milestone title' do
        result = resolve_mr(project, not: { milestone_title: milestone.title })

        expect(result).not_to include(merge_request_with_milestone)
      end
    end

    context 'with review state argument' do
      before_all do
        merge_request_1.merge_request_reviewers.first.update!(state: :requested_changes)
      end

      it 'filters merge requests by reviewers state' do
        result = resolve_mr(project, review_state: :requested_changes)

        expect(result).to contain_exactly(merge_request_1)
      end

      it 'does not find anything' do
        result = resolve_mr(project, review_state: :reviewed)

        expect(result).to be_empty
      end
    end

    context 'with blob path argument' do
      subject(:resolve_query) { resolve_mr(project, blob_path: blob_path, target_branches: target_branches, state: state, created_after: created_after) }

      let(:blob_path) { 'files/ruby/feature.rb' }
      let(:state) { 'opened' }
      let(:target_branches) { ['master'] }
      let(:created_after) { 5.days.ago.to_s }

      it 'filters merge requests by blob path' do
        is_expected.to contain_exactly(merge_request_1)
      end

      context 'when state is not provided' do
        let(:state) { nil }

        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'state field must be specified to filter by blobPath') do
            resolve_query
          end
        end
      end

      context 'when target_branches are not provided' do
        let(:target_branches) { nil }

        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'targetBranches field must be specified to filter by blobPath') do
            resolve_query
          end
        end
      end

      context 'when created_after is not provided' do
        let(:created_after) { nil }

        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'createdAfter field must be specified to filter by blobPath') do
            resolve_query
          end
        end
      end

      context 'when created_after is too much in the past' do
        let(:created_after) { 31.days.ago }

        it 'raises an ArgumentError' do
          expect_graphql_error_to_be_created(Gitlab::Graphql::Errors::ArgumentError, 'createdAfter must be within the last 30 days to filter by blobPath') do
            resolve_query
          end
        end
      end

      context 'when there are no merge requests that changed requested blob' do
        let(:blob_path) { 'unknown' }

        it 'does not find anything' do
          is_expected.to be_empty
        end

        context 'when feature flag "filter_blob_path" is disabled' do
          before do
            stub_feature_flags(filter_blob_path: false)
          end

          it 'ignores requested blob path' do
            is_expected.to contain_exactly(merge_request_1)
          end
        end
      end
    end

    # subscribed filtering handled in request spec, spec/requests/api/graphql/merge_requests/merge_requests_spec.rb

    describe 'combinations' do
      it 'requires all filters' do
        create(:merge_request, :closed, **common_attrs, source_branch: merge_request_4.source_branch)

        result = resolve_mr(project, source_branches: [merge_request_4.source_branch], state: 'locked')

        expect(result).to contain_exactly(merge_request_4)
      end
    end

    context 'when using negated argument' do
      context 'with assignee' do
        it do
          result = resolve_mr(project, not: { assignee_usernames: [current_user.username] })

          expect(result).to contain_exactly(merge_request_1, merge_request_2, merge_request_4, merge_request_5, merge_request_6, merge_request_with_milestone)
        end
      end

      context 'with reviewer' do
        it do
          result = resolve_mr(project, not: { reviewer_username: current_user.username })

          expect(result).to contain_exactly(merge_request_1, merge_request_3, merge_request_4, merge_request_5, merge_request_6, merge_request_with_milestone)
        end
      end
    end

    describe 'sorting' do
      let_it_be(:mrs) do
        [
          merge_request_with_milestone, merge_request_6, merge_request_5, merge_request_4,
          merge_request_3, merge_request_2, merge_request_1
        ]
      end

      context 'when sorting by created' do
        it 'sorts merge requests ascending' do
          expect(resolve_mr(project, sort: 'created_asc'))
            .to match_array(mrs)
            .and be_sorted(:created_at, :asc)
        end

        it 'sorts merge requests descending' do
          expect(resolve_mr(project, sort: 'created_desc'))
            .to match_array(mrs)
            .and be_sorted(:created_at, :desc)
        end
      end

      context 'when sorting by merged at' do
        before do
          merge_request_1.metrics.update!(merged_at: 10.days.ago)
          merge_request_3.metrics.update!(merged_at: 5.days.ago)
        end

        it 'sorts merge requests ascending' do
          expect(resolve_mr(project, sort: :merged_at_asc))
            .to match_array(mrs)
            .and be_sorted(->(mr) { [merged_at(mr), -mr.id] })
        end

        it 'sorts merge requests descending' do
          expect(resolve_mr(project, sort: :merged_at_desc))
            .to match_array(mrs)
            .and be_sorted(->(mr) { [-merged_at(mr), -mr.id] })
        end

        def merged_at(mr)
          nils_last(mr.metrics.merged_at)
        end
      end

      context 'when sorting by closed at' do
        before do
          merge_request_1.metrics.update!(latest_closed_at: 10.days.ago)
          merge_request_3.metrics.update!(latest_closed_at: 5.days.ago)
        end

        it 'sorts merge requests ascending' do
          expect(resolve_mr(project, sort: :closed_at_asc))
            .to match_array(mrs)
            .and be_sorted(->(mr) { [closed_at(mr), -mr.id] })
        end

        it 'sorts merge requests descending' do
          expect(resolve_mr(project, sort: :closed_at_desc))
            .to match_array(mrs)
            .and be_sorted(->(mr) { [-closed_at(mr), -mr.id] })
        end

        def closed_at(mr)
          nils_last(mr.metrics.latest_closed_at)
        end
      end

      context 'when sorting by title' do
        let_it_be(:project) { create(:project, :repository) }
        let_it_be(:mr1) { create(:merge_request, :unique_branches, title: 'foo', source_project: project) }
        let_it_be(:mr2) { create(:merge_request, :unique_branches, title: 'bar', source_project: project) }
        let_it_be(:mr3) { create(:merge_request, :unique_branches, title: 'baz', source_project: project) }
        let_it_be(:mr4) { create(:merge_request, :unique_branches, title: 'Baz 2', source_project: project) }

        it 'sorts issues ascending' do
          expect(resolve_mr(project, sort: :title_asc).to_a).to eq [mr2, mr3, mr4, mr1]
        end

        it 'sorts issues descending' do
          expect(resolve_mr(project, sort: :title_desc).to_a).to eq [mr1, mr4, mr3, mr2]
        end
      end
    end
  end

  def resolve_mr_single(project, iid)
    resolve_mr(project, resolver: described_class.single, iid: iid.to_s)
  end
end
