# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Repositories::RefCommitResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  subject(:commit) { resolve(described_class, obj: ref) }

  let_it_be(:repository) { create(:project, :repository).repository }

  let(:ref) { repository.find_branch('master') }

  describe '#resolve' do
    it 'resolves commit' do
      expect(sync(commit)).to eq(repository.commits('master', limit: 1).last)
    end

    it 'sets project container' do
      expect(sync(commit).container).to eq(repository.project)
    end

    context 'when ref does not exist' do
      let(:ref) { nil }

      it 'returns nil' do
        is_expected.to be_nil
      end
    end

    it 'is N+1 safe' do
      commit_a = repository.commits('master', limit: 1).last
      commit_b = repository.commits('spooky-stuff', limit: 1).last

      commits = batch_sync(max_queries: 2) do
        [
          resolve(described_class, obj: ref),
          resolve(described_class, obj: repository.find_branch('spooky-stuff'))
        ]
      end

      expect(commits).to contain_exactly(commit_a, commit_b)
    end
  end
end
