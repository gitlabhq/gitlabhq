# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::UnprotectedBranchesResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let(:max_page_size) { 100 }
  let(:schema) { GitlabSchema }

  before_all do
    project.add_maintainer(current_user)
  end

  describe '#resolve' do
    let(:first) { nil }
    let(:after) { nil }
    let(:search) { nil }

    let(:arguments) do
      { first: first, after: after, search: search }.compact
    end

    let(:field) do
      ::Types::BaseField.new(
        name: 'unprotected_branches',
        owner: resolver_parent,
        resolver_class: described_class,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        null: true,
        max_page_size: max_page_size,
        calls_gitaly: true
      )
    end

    def resolve_unprotected_branches(args)
      resolve_field(field, project, args: args, object_type: resolver_parent, schema: schema)
    end

    subject(:resolved) { resolve_unprotected_branches(arguments) }

    context 'with pagination' do
      let(:first) { 3 }

      it 'limits results' do
        expect(resolved.items.length).to eq(3)
      end
    end

    context 'when first exceeds max_page_size' do
      let(:max_page_size) { 2 }
      let(:first) { 100 }

      it 'clamps to max_page_size' do
        expect(resolved.items.length).to eq(2)
      end
    end

    context 'with a valid cursor' do
      let(:first) { 3 }

      it 'returns the next page' do
        second_page = resolve_unprotected_branches(first: first, after: resolved.end_cursor)

        expect(second_page.items).to be_present
        expect(second_page.items).not_to match_array(resolved.items)
      end
    end

    context 'when first is 0' do
      let(:first) { 0 }

      it 'returns an empty result' do
        expect(resolved.items).to be_empty
      end
    end

    context 'with search' do
      let(:search) { 'feature' }
      let(:first) { 100 }

      it 'filters branches by search term' do
        expect(resolved.items).to be_present
        expect(resolved.items).to all(include('feature'))
      end
    end
  end
end
