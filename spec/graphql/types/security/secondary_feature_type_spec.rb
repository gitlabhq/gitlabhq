# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Security::SecondaryFeatureType, feature_category: :security_asset_inventories do
  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(
      :configuration_text,
      :description,
      :name,
      :type
    )
  end
end
