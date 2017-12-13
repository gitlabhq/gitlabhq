require 'spec_helper'

describe BaseCountService do
  include ::EE::GeoHelpers

  describe '#cache_options' do
    subject { described_class.new.cache_options }

    it 'returns the default' do
      stub_current_geo_node(nil)

      is_expected.to include(:raw)
      is_expected.not_to include(:expires_in)
    end

    it 'returns default on a Geo primary' do
      stub_current_geo_node(create(:geo_node, :primary))

      is_expected.to include(:raw)
      is_expected.not_to include(:expires_in)
    end

    it 'returns cache of 20 mins on a Geo secondary' do
      stub_current_geo_node(create(:geo_node))

      is_expected.to include(:raw)
      is_expected.to include(expires_in: 20.minutes)
    end
  end
end
