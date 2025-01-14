# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::ResourceType, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResource') }

  it 'exposes the expected fields' do
    expected_fields = %i[
      id
      name
      description
      icon
      full_path
      web_path
      versions
      latest_released_at
      verification_level
      visibility_level
      star_count
      starrers_path
      topics
      last_30_day_usage_count
    ]

    expect(described_class).to have_graphql_fields(*expected_fields)
  end
end
