# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::VersionType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceVersion') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      created_at
      released_at
      tag_name
      tag_path
      author
      commit
      components
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
