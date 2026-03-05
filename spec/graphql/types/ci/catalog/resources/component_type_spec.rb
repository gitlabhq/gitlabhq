# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::ComponentType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceComponent') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      inputs
      name
      include_path
      description
      last_30_day_usage_count
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end

  describe '#description' do
    let_it_be(:project) { create(:project) }
    let_it_be(:catalog_resource) { create(:ci_catalog_resource, project: project) }
    let_it_be(:version) { create(:ci_catalog_resource_version, catalog_resource: catalog_resource) }

    let(:component) do
      create(:ci_catalog_resource_component,
        version: version,
        catalog_resource: catalog_resource,
        project: project,
        spec: spec
      )
    end

    let(:query) { GraphQL::Query.new(GitlabSchema) }
    let(:context) { GraphQL::Query::Context.new(query: query, values: {}) }
    let(:component_type) { described_class.authorized_new(component, context) }

    context 'when spec contains a description' do
      let(:spec) do
        {
          'description' => 'A helpful component description',
          'inputs' => { 'foo' => { 'default' => 'bar' } }
        }
      end

      it 'returns the description' do
        expect(component_type.description).to eq('A helpful component description')
      end
    end

    context 'when spec does not contain a description' do
      let(:spec) do
        {
          'inputs' => { 'foo' => { 'default' => 'bar' } }
        }
      end

      it 'returns nil' do
        expect(component_type.description).to be_nil
      end
    end
  end
end
