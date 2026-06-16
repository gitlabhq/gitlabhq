# frozen_string_literal: true

require 'spec_helper'

RSpec.describe MergeRequests::StackFinder, feature_category: :code_review_workflow do
  def create_merge_request(source_branch:, target_branch:, state: :opened)
    create(:merge_request, state: state, source_project: project, target_project: project,
      source_branch: source_branch, target_branch: target_branch,
      skip_branch_existence_check: true)
  end

  let_it_be(:user) { create(:user) }
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
