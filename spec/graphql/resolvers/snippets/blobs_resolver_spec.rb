# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Snippets::BlobsResolver do
  include GraphqlHelpers

  specify do
    expect(described_class).to have_nullable_graphql_type(Types::Snippets::BlobType.connection_type)
  end

  describe '#resolve' do
    let_it_be(:current_user) { create(:user) }
    let_it_be(:snippet) { create(:personal_snippet, :private, :repository, author: current_user) }

    context 'when user is not authorized' do
      let(:other_user) { create(:user) }

      it 'raises an error' do
        expect do
          resolve_blobs(snippet, user: other_user)
        end.to raise_error(Gitlab::Graphql::Errors::ResourceNotAvailable)
      end
    end

    context 'when using no filter' do
      it 'returns all snippet blobs' do
        expect(resolve_blobs(snippet).map(&:path)).to contain_exactly(*snippet.list_files)
      end
    end

    context 'when using filters' do
      context 'when paths is a single string' do
        it 'returns an array of files' do
          path = 'CHANGELOG'

          expect(resolve_blobs(snippet, args: { paths: path }).first.path).to eq(path)
        end
      end

      context 'when paths is an array of string' do
        it 'returns an array of files' do
          paths = ['CHANGELOG', 'README.md']

          expect(resolve_blobs(snippet, args: { paths: paths }).map(&:path)).to contain_exactly(*paths)
        end
      end
    end
  end

  def resolve_blobs(snippet, user: current_user, args: {})
    resolve(described_class, args: args, ctx: { current_user: user }, obj: snippet)
  end
end
