# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::ComponentType, feature_category: :pipeline_composition do
  let(:component_type) { described_class.authorized_new(component, context) }
  let(:context) { GraphQL::Query::Context.new(query: query, values: {}) }
  let(:query) { GraphQL::Query.new(GitlabSchema) }
  let(:component) { create(:ci_catalog_resource_component, version: version, spec: spec) }
  let_it_be(:version, freeze: false) { create(:ci_catalog_resource_version) }

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

  describe '#inputs' do
    # The input names are deliberately neither in `inputs` order nor in length order, so that the
    # assertions fail if `inputs_order` is not applied.
    let(:inputs) do
      {
        'stage' => { 'default' => 'test' },
        'environment' => { 'description' => 'Deployment target' },
        'n' => { 'type' => 'number' }
      }
    end

    context 'when spec contains inputs_order' do
      let(:spec) { { 'inputs' => inputs, 'inputs_order' => %w[environment n stage] } }

      it 'returns the inputs in the recorded order' do
        expect(component_type.inputs.pluck(:name)).to eq(%w[environment n stage])
      end

      it 'returns the fields of each input' do
        expect(component_type.inputs).to include(
          {
            name: 'environment',
            required?: true,
            default: nil,
            description: 'Deployment target',
            regex: nil,
            type: 'string',
            rules: nil
          },
          {
            name: 'stage',
            required?: false,
            default: 'test',
            description: nil,
            regex: nil,
            type: 'string',
            rules: nil
          }
        )
      end
    end

    context 'when spec does not contain inputs' do
      let(:spec) { { 'description' => 'A component without inputs' } }

      it 'returns no inputs' do
        expect(component_type.inputs).to be_empty
      end
    end
  end
end
