# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::VersionType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceVersion') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      author
      commit
      components
      created_at
      id
      name
      path
      readme
      readme_html
      released_at
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
