# frozen_string_literal: true

require 'spec_helper'

describe Resolvers::BranchCommitResolver do
  include GraphqlHelpers

  subject(:commit) { resolve(described_class, obj: branch) }

  let_it_be(:repository) { create(:project, :repository).repository }
  let(:branch) { repository.find_branch('master') }

  describe '#resolve' do
    it 'resolves commit' do
      is_expected.to eq(repository.commits('master', limit: 1).last)
    end

    context 'when branch does not exist' do
      let(:branch) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end
  end
end
