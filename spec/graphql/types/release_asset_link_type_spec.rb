# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GitlabSchema.types['ReleaseAssetLink'] do
  it { expect(described_class).to require_graphql_authorizations(:read_release) }

  it 'has the expected fields' do
    expected_fields = %w[
      id name url external link_type direct_asset_url direct_asset_path
    ]

    expect(described_class).to include_graphql_fields(*expected_fields)
  end
end
