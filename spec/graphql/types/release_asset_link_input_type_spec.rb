# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Types::ReleaseAssetLinkInputType do
  specify { expect(described_class.graphql_name).to eq('ReleaseAssetLinkInput') }

  it 'has the correct arguments' do
    expect(described_class.arguments.keys).to match_array(%w[name url directAssetPath linkType])
  end

  it 'sets the type of link_type argument to ReleaseAssetLinkTypeEnum' do
    expect(described_class.arguments['linkType'].type).to eq(Types::ReleaseAssetLinkTypeEnum)
  end
end
