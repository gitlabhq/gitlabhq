# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::MergeRequestsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }
  let_it_be(:common_attrs) { { author: current_user, source_project: project, target_project: project } }
  let_it_be(:merge_request_1) { create(:merge_request, :simple, **common_attrs) }
  let_it_be(:merge_request_2) { create(:merge_request, :rebased, **common_attrs) }
  let_it_be(:merge_request_3) { create(:merge_request, :unique_branches, **common_attrs) }
  let_it_be(:merge_request_4) { create(:merge_request, :unique_branches, :locked, **common_attrs) }
  let_it_be(:merge_request_5) { create(:merge_request, :simple, :locked, **common_attrs) }
  let_it_be(:merge_request_6) { create(:labeled_merge_request, :unique_branches, labels: create_list(:label, 2), **common_attrs) }
  let_it_be(:other_project) { create(:project, :repository) }
  let_it_be(:other_merge_request) { create(:merge_request, source_project: other_project, target_project: other_project) }
  let(:iid_1) { merge_request_1.iid }
  let(:iid_2) { merge_request_2.iid }
  let(:other_iid) { other_merge_request.iid }

  before do
    project.add_developer(current_user)
  end

  describe '#resolve' do
    context 'no arguments' do
      it 'returns all merge requests' do
        result = resolve_mr(project, {})

        expect(result).to contain_exactly(merge_request_1, merge_request_2, merge_request_3, merge_request_4, merge_request_5, merge_request_6)
      end

      it 'returns only merge requests that the current user can see' do
        result = resolve_mr(project, {}, user: build(:user))

        expect(result).to be_empty
      end
    end

    context 'by iid alone' do
      it 'batch-resolves by target project full path and individual IID' do
        result = batch_sync(max_queries: 2) do
          [iid_1, iid_2].map { |iid| resolve_mr_single(project, iid) }
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2)
      end

      it 'batch-resolves by target project full path and IIDS' do
        result = batch_sync(max_queries: 2) do
          resolve_mr(project, iids: [iid_1, iid_2])
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2)
      end

      it 'can batch-resolve merge requests from different projects' do
        result = batch_sync(max_queries: 3) do
          resolve_mr(project, iids: iid_1) +
            resolve_mr(project, iids: iid_2) +
            resolve_mr(other_project, iids: other_iid)
        end

        expect(result).to contain_exactly(merge_request_1, merge_request_2, other_merge_request)
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

    context 'by source branches' do
      it 'takes one argument' do
        result = resolve_mr(project, source_branch: [merge_request_3.source_branch])

        expect(result).to contain_exactly(merge_request_3)
      end

      it 'takes more than one argument' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:source_branch)
        result = resolve_mr(project, source_branch: branches )

        expect(result).to match_array(mrs)
      end
    end

    context 'by target branches' do
      it 'takes one argument' do
        result = resolve_mr(project, target_branch: [merge_request_3.target_branch])

        expect(result).to contain_exactly(merge_request_3)
      end

      it 'takes more than one argument' do
        mrs = [merge_request_3, merge_request_4]
        branches = mrs.map(&:target_branch)
        result = resolve_mr(project, target_branch: branches )

        expect(result.compact).to match_array(mrs)
      end
    end

    context 'by state' do
      it 'takes one argument' do
        result = resolve_mr(project, state: 'locked')

        expect(result).to contain_exactly(merge_request_4, merge_request_5)
      end
    end

    context 'by label' do
      let_it_be(:label) { merge_request_6.labels.first }
      let_it_be(:with_label) { create(:labeled_merge_request, :closed, labels: [label], **common_attrs) }

      it 'takes one argument' do
        result = resolve_mr(project, label_name: [label.title])

        expect(result).to contain_exactly(merge_request_6, with_label)
      end

      it 'takes multiple arguments, with semantics of ALL MUST MATCH' do
        result = resolve_mr(project, label_name: merge_request_6.labels.map(&:title))

        expect(result).to contain_exactly(merge_request_6)
      end
    end

    describe 'combinations' do
      it 'requires all filters' do
        create(:merge_request, :closed, source_project: project, target_project: project, source_branch: merge_request_4.source_branch)

        result = resolve_mr(project, source_branch: [merge_request_4.source_branch], state: 'locked')

        expect(result.compact).to contain_exactly(merge_request_4)
      end
    end
  end

  def resolve_mr_single(project, iid)
    resolve_mr(project, { iids: iid }, resolver: described_class.single)
  end

  def resolve_mr(project, args, resolver: described_class, user: current_user)
    resolve(resolver, obj: project, args: args, ctx: { current_user: user })
  end
end
