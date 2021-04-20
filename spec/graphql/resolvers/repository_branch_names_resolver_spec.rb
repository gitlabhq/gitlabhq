# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::RepositoryBranchNamesResolver do
  include GraphqlHelpers

  let(:project) { create(:project, :repository) }

  describe '#resolve' do
    subject(:resolve_branch_names) do
      resolve(
        described_class,
        obj: project.repository,
        args: { search_pattern: pattern },
        ctx: { current_user: project.creator }
      )
    end

    context 'with empty search pattern' do
      let(:pattern) { '' }

      it 'returns nil' do
        expect(resolve_branch_names).to eq(nil)
      end
    end

    context 'with a valid search pattern' do
      let(:pattern) { 'mas*' }

      it 'returns matching branches' do
        expect(resolve_branch_names).to match_array(['master'])
      end
    end
  end
end
