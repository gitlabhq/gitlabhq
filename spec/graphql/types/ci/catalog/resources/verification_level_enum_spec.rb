# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Ci::Catalog::Resources::VerificationLevelEnum, feature_category: :pipeline_composition do
  specify { expect(described_class.graphql_name).to eq('CiCatalogResourceVerificationLevel') }

  it 'exposes the expected values' do
    expected_values = %w[UNVERIFIED GITLAB_MAINTAINED GITLAB_PARTNER_MAINTAINED VERIFIED_CREATOR_MAINTAINED]

    expect(described_class.values.keys).to match_array(expected_values)
  end
end
