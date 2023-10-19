# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::Ci::Catalog::ResourcesResolver, feature_category: :pipeline_composition do
  include GraphqlHelpers

  let_it_be(:namespace) { create(:group) }
  let_it_be(:project_1) { create(:project, name: 'Z', namespace: namespace) }
  let_it_be(:project_2) { create(:project, name: 'A', namespace: namespace) }
  let_it_be(:project_3) { create(:project, name: 'L', namespace: namespace) }
  let_it_be(:resource_1) { create(:ci_catalog_resource, project: project_1) }
  let_it_be(:resource_2) { create(:ci_catalog_resource, project: project_2) }
  let_it_be(:resource_3) { create(:ci_catalog_resource, project: project_3) }
  let_it_be(:user) { create(:user) }

  describe '#resolve' do
    context 'with an authorized user' do
      before_all do
        namespace.add_owner(user)
      end

      before do
        stub_licensed_features(ci_namespace_catalog: true)
      end

      it 'returns all CI Catalog resources visible to the current user in the namespace' do
        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

        expect(result.items.count).to be(3)
        expect(result.items.pluck(:name)).to contain_exactly('Z', 'A', 'L')
      end

      it 'returns all resources sorted by descending created date when given no sort param' do
        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

        expect(result.items.pluck(:name)).to eq(%w[L A Z])
      end

      it 'returns all CI Catalog resources sorted by descending name when there is a sort parameter' do
        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path, sort:
        'NAME_DESC' })

        expect(result.items.pluck(:name)).to eq(%w[Z L A])
      end
    end

    context 'when the current user cannot read the namespace catalog' do
      it 'raises ResourceNotAvailable' do
        stub_licensed_features(ci_namespace_catalog: true)
        namespace.add_guest(user)

        result = resolve(described_class, ctx: { current_user: user }, args: { project_path: project_1.full_path })

        expect(result).to be_empty
      end
    end
  end
end
