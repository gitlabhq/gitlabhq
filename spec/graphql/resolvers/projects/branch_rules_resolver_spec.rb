# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Projects::BranchRulesResolver, feature_category: :source_code_management do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user) }

  let_it_be(:protected_branch_a) { create(:protected_branch, project: project, name: 'a') }
  let_it_be(:protected_branch_b) { create(:protected_branch, project: project, name: 'b') }
  let_it_be(:protected_branch_c) { create(:protected_branch, project: project, name: 'g') }
  let_it_be(:protected_branch_d) { create(:protected_branch, project: project, name: 'd') }
  let_it_be(:protected_branch_e) { create(:protected_branch, project: project, name: 'e') }

  let(:max_page_size) { 100 }
  let(:default_page_size) { 20 }
  let(:schema) { GitlabSchema }

  before_all do
    project.add_maintainer(current_user)
  end

  describe '#resolve' do
    let(:first) { nil }
    let(:after) { nil }

    let(:arguments) do
      {
        first: first,
        after: after
      }
    end

    subject(:resolved) do
      field = ::Types::BaseField.from_options(
        'field_value',
        name: 'branch_rules',
        owner: resolver_parent,
        resolver_class: described_class,
        connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
        null: true,
        max_page_size: max_page_size
      )

      resolve_field(field, project, args: arguments, object_type: resolver_parent, schema: schema)
    end

    it 'returns an externally paginated array connection' do
      expect(resolved).to be_a(Gitlab::Graphql::Pagination::ExternallyPaginatedArrayConnection)
    end

    context 'without pagination arguments' do
      it 'returns branch rules' do
        expect(resolved.items.size).to eq(6)
      end

      it 'includes custom rules and protected branches' do
        items = resolved.items

        expect(items.first).to be_a(Projects::AllBranchesRule)
        expect(items[1].protected_branch.name).to eq(protected_branch_a.name)
        expect(items[2].protected_branch.name).to eq(protected_branch_b.name)
        expect(items[3].protected_branch.name).to eq(protected_branch_d.name)
      end

      it 'includes pagination metadata' do
        expect(resolved.end_cursor).to be_nil
        expect(resolved.has_next_page).to be false
      end
    end

    context 'with first argument' do
      let(:first) { 2 }

      it 'limits results to the specified count' do
        expect(resolved.items.size).to eq(2)
      end

      it 'indicates there is a next page' do
        expect(resolved.has_next_page).to be true
        expect(resolved.end_cursor).to be_present
      end
    end

    context 'with after cursor' do
      let(:first_page) do
        field = ::Types::BaseField.from_options(
          'field_value',
          name: 'branch_rules',
          owner: resolver_parent,
          resolver_class: described_class,
          connection_extension: Gitlab::Graphql::Extensions::ForwardOnlyExternallyPaginatedArrayExtension,
          null: true,
          max_page_size: max_page_size,
          default_page_size: default_page_size
        )

        resolve_field(field, project, args: { first: 2 }, object_type: resolver_parent, schema: schema)
      end

      let(:after) { first_page.end_cursor }
      let(:first) { 2 }

      it 'returns results after the cursor' do
        items = resolved.items

        expect(items.size).to eq(2)
        expect(items[0].protected_branch.name).to eq(protected_branch_b.name)
        expect(items[1].protected_branch.name).to eq(protected_branch_d.name)
      end

      it 'has correct pagination metadata' do
        expect(resolved.has_next_page).to be true
        expect(resolved.end_cursor).to be_present
      end
    end

    context 'when all results fit in one page' do
      let(:first) { 10 }

      it 'indicates there is no next page' do
        expect(resolved.has_next_page).to be false
      end

      it 'has nil end cursor' do
        expect(resolved.end_cursor).to be_nil
      end
    end
  end
end
