# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Repositories::CommitResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  subject(:commit) { resolve(described_class, obj: repository, args: { ref: ref }) }

  let_it_be(:repository) { create(:project, :repository).repository }

  let(:ref) { 'master' }

  it { expect(described_class).to have_nullable_graphql_type(Types::Repositories::CommitType) }

  describe '#resolve' do
    it 'resolves commit' do
      expect(commit).to eq(repository.commit('master'))
    end

    context 'when ref is empty' do
      let(:ref) { '' }

      it { is_expected.to be_nil }
    end

    context 'when ref is not found' do
      let(:ref) { 'unknown' }

      it { is_expected.to be_nil }
    end
  end
end
