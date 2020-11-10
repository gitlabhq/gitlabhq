# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::TreeResolver do
  include GraphqlHelpers

  let(:repository) { create(:project, :repository).repository }

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Tree::TreeType)
  end

  describe '#resolve' do
    it 'resolves to a tree' do
      result = resolve_repository({ ref: "master" })

      expect(result).to be_an_instance_of(Tree)
    end

    it 'resolve to a recursive tree' do
      result = resolve_repository({ ref: "master", recursive: true })

      expect(result.trees[4].path).to eq('files/html')
    end

    context 'when repository does not exist' do
      it 'returns nil' do
        allow(repository).to receive(:exists?).and_return(false)

        result = resolve_repository({ ref: "master" })

        expect(result).to be(nil)
      end
    end
  end

  def resolve_repository(args)
    resolve(described_class, obj: repository, args: args)
  end
end
