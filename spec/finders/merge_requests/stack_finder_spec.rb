# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::StackFinder, feature_category: :code_review_workflow do
  def create_merge_request(source_branch:, target_branch:, state: :opened, author: project.creator)
    create(:merge_request, state: state, source_project: project, target_project: project,
      source_branch: source_branch, target_branch: target_branch, author: author,
      skip_branch_existence_check: true)
  end

  let_it_be(:user) { create(:user) }
  let_it_be(:other_author) { create(:user) }
  let_it_be(:project) { create(:project, :repository) }

  let_it_be(:merge_request_1) do
    create_merge_request(source_branch: 'feature-1', target_branch: project.default_branch)
  end

  let_it_be(:merge_request_2) do
    create_merge_request(source_branch: 'feature-2', target_branch: 'feature-1')
  end

  let_it_be(:merge_request_3) do
    create_merge_request(source_branch: 'feature-3', target_branch: 'feature-2')
  end

  describe '#execute' do
    context 'when the merge request is not open' do
      let_it_be(:merge_request_1) do
        create_merge_request(state: :closed, source_branch: 'feature-1', target_branch: project.default_branch)
      end

      it 'returns none' do
        expect(described_class.new(user, merge_request_1).execute).to be_none
      end
    end

    context 'when the merge request is not part of a stack' do
      let_it_be(:merge_request) do
        create_merge_request(source_branch: 'feature-x', target_branch: project.default_branch)
      end

      it 'returns none' do
        expect(described_class.new(user, merge_request).execute).to be_none
      end
    end

    context 'with a merge request stack' do
      it 'returns the full stack when given the top merge request' do
        expect(described_class.new(user, merge_request_1).execute.to_a).to eq([
          merge_request_1, merge_request_2, merge_request_3
        ])
      end

      it 'returns the full stack when given the middle merge request' do
        expect(described_class.new(user, merge_request_2).execute.to_a).to eq([
          merge_request_1, merge_request_2, merge_request_3
        ])
      end

      it 'returns the full stack when given the bottom merge request' do
        expect(described_class.new(user, merge_request_3).execute.to_a).to eq([
          merge_request_1, merge_request_2, merge_request_3
        ])
      end
    end

    context 'when a merge request in the middle of the chain has a different author' do
      let_it_be(:top) do
        create_merge_request(source_branch: 'mid-top', target_branch: project.default_branch)
      end

      let_it_be(:foreign) do
        create_merge_request(source_branch: 'mid-foreign', target_branch: 'mid-top', author: other_author)
      end

      let_it_be(:bottom) do
        create_merge_request(source_branch: 'mid-bottom', target_branch: 'mid-foreign')
      end

      it 'truncates the chain and excludes the other author when given the top merge request' do
        result = described_class.new(user, top).execute

        expect(result).to be_none
      end

      it 'truncates the chain and excludes the other author when given the bottom merge request' do
        result = described_class.new(user, bottom).execute

        expect(result).to be_none
      end
    end

    context 'when a longer stack is split by a different author' do
      let_it_be(:seg_1) do
        create_merge_request(source_branch: 'seg-1', target_branch: project.default_branch)
      end

      let_it_be(:seg_2) do
        create_merge_request(source_branch: 'seg-2', target_branch: 'seg-1')
      end

      let_it_be(:foreign) do
        create_merge_request(source_branch: 'seg-foreign', target_branch: 'seg-2', author: other_author)
      end

      let_it_be(:seg_4) do
        create_merge_request(source_branch: 'seg-4', target_branch: 'seg-foreign')
      end

      it 'returns the contiguous same-author segment reachable from the input' do
        result = described_class.new(user, seg_1).execute

        expect(result.to_a).to match_array([seg_1, seg_2])
      end
    end

    context 'when the up-chain is split by a different author' do
      let_it_be(:foreign_top) do
        create_merge_request(source_branch: 'up-1', target_branch: project.default_branch, author: other_author)
      end

      let_it_be(:up_2) do
        create_merge_request(source_branch: 'up-2', target_branch: 'up-1')
      end

      let_it_be(:up_3) do
        create_merge_request(source_branch: 'up-3', target_branch: 'up-2')
      end

      it 'truncates the up-chain and returns the non-empty same-author segment' do
        result = described_class.new(user, up_3).execute

        expect(result.to_a).to match_array([up_2, up_3])
      end
    end

    context 'when the oldest same-branch sibling has a different author' do
      let_it_be(:fork_top) do
        create_merge_request(source_branch: 'fork-top', target_branch: project.default_branch)
      end

      let_it_be(:foreign_sibling) do
        create_merge_request(source_branch: 'fork-foreign', target_branch: 'fork-top', author: other_author)
      end

      let_it_be(:same_sibling) do
        create_merge_request(source_branch: 'fork-same', target_branch: 'fork-top')
      end

      it 'skips the lower-id foreign sibling and follows the same-author sibling', :aggregate_failures do
        result = described_class.new(user, fork_top).execute

        expect(result.to_a).to match_array([fork_top, same_sibling])
      end
    end

    context 'when the only adjacent merge request has a different author' do
      context 'and it is a child below the input' do
        let_it_be(:merge_request) do
          create_merge_request(source_branch: 'solo-source', target_branch: project.default_branch)
        end

        let_it_be(:foreign_child) do
          create_merge_request(source_branch: 'solo-child', target_branch: 'solo-source', author: other_author)
        end

        it 'returns none' do
          expect(described_class.new(user, merge_request).execute).to be_none
        end
      end

      context 'and it is a parent above the input' do
        let_it_be(:merge_request) do
          create_merge_request(source_branch: 'pc-source', target_branch: 'pc-mid')
        end

        let_it_be(:foreign_parent) do
          create_merge_request(source_branch: 'pc-mid', target_branch: project.default_branch, author: other_author)
        end

        it 'returns none' do
          expect(described_class.new(user, merge_request).execute).to be_none
        end
      end
    end

    context 'when merge requests in the chain are closed' do
      let_it_be(:merge_request_2) do
        create_merge_request(state: :closed, source_branch: 'feature-2', target_branch: 'feature-1')
      end

      it 'breaks the chain' do
        expect(described_class.new(user, merge_request_2).execute).to be_none
      end
    end

    context 'when merge requests in the chain are merged' do
      let_it_be(:merge_request_2) do
        create_merge_request(state: :merged, source_branch: 'feature-2', target_branch: 'feature-1')
      end

      it 'breaks the chain' do
        expect(described_class.new(user, merge_request_2).execute).to be_none
      end
    end

    context 'when branch names form a cycle' do
      it 'terminates without looping infinitely' do
        merge_request_a = create_merge_request(source_branch: 'cycle-a', target_branch: 'cycle-b')
        create_merge_request(source_branch: 'cycle-b', target_branch: 'cycle-a')

        result = described_class.new(user, merge_request_a).execute

        expect(result.size).to be <= described_class::MAX_STACK_SIZE
      end
    end

    context 'when the stack exceeds MAX_STACK_SIZE' do
      it 'stops at MAX_STACK_SIZE entries' do
        merge_requests = []
        merge_requests << create_merge_request(source_branch: 'stack-branch-0', target_branch: project.default_branch)

        described_class::MAX_STACK_SIZE.times do |i|
          merge_requests << create_merge_request(
            source_branch: "stack-branch-#{i + 1}",
            target_branch: "stack-branch-#{i}"
          )
        end

        expect(described_class.new(user, merge_requests.first).execute.size).to eq(described_class::MAX_STACK_SIZE)
      end
    end
  end
end
