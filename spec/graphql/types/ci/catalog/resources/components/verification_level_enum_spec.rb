# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::Components::VerificationLevelEnum, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceComponentVerificationLevel') }

  it 'exposes the expected values' do
    expected_values = %w[UNVERIFIED GITLAB]

    expect(described_class.values.keys).to match_array(expected_values)
  end
end
