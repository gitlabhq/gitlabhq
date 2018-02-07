require 'spec_helper'

describe Gitlab::Geo::GeoTasks do
  describe '.set_primary_geo_node' do
    before do
      allow(GeoNode).to receive(:current_node_url).and_return('https://primary.geo.example.com')
    end

    it 'sets the primary node' do
      expect { subject.set_primary_geo_node }.to output(%r{https://primary.geo.example.com/ is now the primary Geo node}).to_stdout
    end

    it 'returns error when there is already a Primary node' do
      create(:geo_node, :primary)

      expect { subject.set_primary_geo_node }.to output(/Error saving Geo node:/).to_stdout
    end
  end
end
