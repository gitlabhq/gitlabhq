# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequestsResolver do
  include GraphqlHelpers
  include SortingHelper

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:other_project) { create(:project, :repository) }
  let_it_be(:milestone) { create(:milestone, project: project) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:other_user) { create(:user) }
  let_it_be(:common_attrs) { { author: current_user, source_project: project, target_project: project } }
  let_it_be(:merge_request_1) { create(:merge_request, :simple, **common_attrs) }
  let_it_be(:merge_request_2) { create(:merge_request, :rebased, **common_attrs) }
  let_it_be(:merge_request_3) { create(:merge_request, :unique_branches, **common_attrs) }
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
        # 2 queries for project_authorizations, and 2 for merge_requests
        results = batch_sync(max_queries: queries_per_project * 2) do
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

    context 'with state argument' do
      it 'takes one argument' do
        result = resolve_mr(project, state: 'locked')

        expect(result).to contain_exactly(merge_request_4, merge_request_5)
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

    context 'with negated milestone argument' do
      it 'filters out merge requests with given milestone title' do
        result = resolve_mr(project, not: { milestone_title: milestone.title })

        expect(result).not_to include(merge_request_with_milestone)
      end
    end

    describe 'combinations' do
      it 'requires all filters' do
        create(:merge_request, :closed, **common_attrs, source_branch: merge_request_4.source_branch)

        result = resolve_mr(project, source_branches: [merge_request_4.source_branch], state: 'locked')

        expect(result).to contain_exactly(merge_request_4)
      end
    end

    describe 'sorting' do
      let(:mrs) do
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

        context 'when label filter is given and the optimized_issuable_label_filter feature flag is off' do
          before do
            stub_feature_flags(optimized_issuable_label_filter: false)
          end

          it 'does not raise PG::GroupingError' do
            expect { resolve_mr(project, sort: :merged_at_desc, labels: %w[a b]) }.not_to raise_error
          end
        end
      end
    end
  end

  def resolve_mr_single(project, iid)
    resolve_mr(project, resolver: described_class.single, iid: iid.to_s)
  end

  def resolve_mr(project, resolver: described_class, user: current_user, **args)
    resolve(resolver, obj: project, args: args, ctx: { current_user: user })
  end
end
