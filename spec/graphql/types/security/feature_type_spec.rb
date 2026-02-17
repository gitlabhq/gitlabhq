# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::Security::FeatureType, feature_category: :security_asset_inventories do
  it 'has expected fields' do
    expect(described_class).to have_graphql_fields(
      :anchor,
      :configuration_help_path,
      :description,
      :help_path,
      :name,
      :secondary,
      :short_name,
      :type
    )
  end
end
