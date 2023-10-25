# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourcesResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_1) { create(:project, name: 'Z', namespace: namespace) }
  let_it_be(:project_2) { create(:project, name: 'A_Test', namespace: namespace) }
  let_it_be(:project_3) { create(:project, name: 'L', description: 'Test', namespace: namespace) }
  let_it_be(:resource_1) { create(:ci_catalog_resource, project: project_1) }
  let_it_be(:resource_2) { create(:ci_catalog_resource, project: project_2) }
  let_it_be(:resource_3) { create(:ci_catalog_resource, project: project_3) }
  let_it_be(:user) { create(:user) }

  let(:ctx) { { current_user: user } }
  let(:search) { nil }
  let(:sort) { nil }

  let(:args) do
    {
      project_path: project_1.full_path,
      sort: sort,
      search: search
    }.compact
  end

  subject(:result) { resolve(described_class, ctx: ctx, args: args) }

  describe '#resolve' do
    context 'with an authorized user' do
      before_all do
        namespace.add_owner(user)
      end

      it 'returns all catalog resources visible to the current user in the namespace' do
        expect(result.items.count).to be(3)
        expect(result.items.pluck(:name)).to contain_exactly('Z', 'A_Test', 'L')
      end

      context 'when the sort parameter is not provided' do
        it 'returns all catalog resources sorted by descending created date' do
          expect(result.items.pluck(:name)).to eq(%w[L A_Test Z])
        end
      end

      context 'when the sort parameter is provided' do
        let(:sort) { 'NAME_DESC' }

        it 'returns all catalog resources sorted by descending name' do
          expect(result.items.pluck(:name)).to eq(%w[Z L A_Test])
        end
      end

      context 'when the search parameter is provided' do
        let(:search) { 'test' }

        it 'returns the catalog resources that match the search term' do
          expect(result.items.pluck(:name)).to contain_exactly('A_Test', 'L')
        end
      end
    end

    context 'when the current user cannot read the namespace catalog' do
      it 'returns empty response' do
        expect(result).to be_empty
      end
    end
  end
end
