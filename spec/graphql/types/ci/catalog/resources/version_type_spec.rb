# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::VersionType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceVersion') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      created_at
      released_at
      name
      path
      author
      commit
      components
      readme_html
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
