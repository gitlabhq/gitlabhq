# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::MergeRequests::StackResolver, feature_category: :code_review_workflow do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user, developer_of: project) }

  def create_merge_request(source_branch:, target_branch:)
    create(:merge_request, source_project: project, target_project: project,
      source_branch: source_branch, target_branch: target_branch,
      skip_branch_existence_check: true)
  end

  def resolve_stack(merge_request)
    resolve(described_class, obj: merge_request, ctx: { current_user: current_user })
  end

  describe '#resolve' do
    context 'when the merge request is part of a stack' do
      let_it_be(:merge_request_1) do
        create_merge_request(source_branch: 'feature-1', target_branch: project.default_branch)
      end

      let_it_be(:merge_request_2) do
        create_merge_request(source_branch: 'feature-2', target_branch: 'feature-1')
      end

      let_it_be(:merge_request_3) do
        create_merge_request(source_branch: 'feature-3', target_branch: 'feature-2')
      end

      it 'returns the full stack in order' do
        expect(resolve_stack(merge_request_2)).to eq([merge_request_1, merge_request_2, merge_request_3])
      end
    end

    context 'when the merge request is not part of a stack' do
      it 'returns an empty list' do
        merge_request = create_merge_request(source_branch: 'feature-1', target_branch: project.default_branch)

        expect(resolve_stack(merge_request)).to eq([])
      end
    end
  end
end
