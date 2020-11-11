# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ReleaseAssetsInputType do
  specify { expect(described_class.graphql_name).to eq('ReleaseAssetsInput') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[links])
  end

  it 'sets the type of links argument to ReleaseAssetLinkInputType' do
    expect(described_class.arguments['links'].type.of_type.of_type).to eq(Types::ReleaseAssetLinkInputType)
  end
end
