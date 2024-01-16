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
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
