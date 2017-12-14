require 'spec_helper'

describe Geo::NodeUpdateService do
  let(:groups) { create_list(:group, 2) }
  let!(:primary) { create(:geo_node, :primary) }
  let(:geo_node) { create(:geo_node) }
  let(:geo_node_with_restrictions) { create(:geo_node, namespace_ids: [groups.first.id]) }

  describe '#execute' do
    it 'updates the node' do
      params = { url: 'http://example.com' }
      service = described_class.new(geo_node, params)

      service.execute

      geo_node.reload
      expect(geo_node.url.chomp('/')).to eq(params[:url])
    end

    it 'returns true when update succeeds' do
      service = described_class.new(geo_node, { url: 'http://example.com' })

      expect(service.execute).to eq true
    end

    it 'returns false when update fails' do
      allow(geo_node).to receive(:update).and_return(false)

      service = described_class.new(geo_node, { url: 'http://example.com' })

      expect(service.execute).to eq false
    end

    it 'logs an event to the Geo event log when namespaces change' do
      service = described_class.new(geo_node, namespace_ids: groups.map(&:id).join(','))

      expect { service.execute }.to change(Geo::RepositoriesChangedEvent, :count).by(1)
    end

    it 'does not log an event to the Geo event log when removing namespace restrictions' do
      service = described_class.new(geo_node_with_restrictions, namespace_ids: '')

      expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
    end

    it 'does not log an event to the Geo event log when node is a primary node' do
      service = described_class.new(primary, namespace_ids: groups.map(&:id).join(','))

      expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
    end
  end
end
