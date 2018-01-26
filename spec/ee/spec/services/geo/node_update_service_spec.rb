require 'spec_helper'

describe Geo::NodeUpdateService do
  set(:primary) { create(:geo_node, :primary) }

  let(:geo_node) { create(:geo_node) }
  let(:groups) { create_list(:group, 2) }
  let(:namespace_ids) { groups.map(&:id).join(',') }

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

    context 'selective sync disabled' do
      it 'does not log an event to the Geo event log when adding restrictions' do
        service = described_class.new(geo_node, namespace_ids: namespace_ids, selective_sync_shards: ['default'])

        expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
      end
    end

    context 'selective sync by namespaces' do
      let(:restricted_geo_node) { create(:geo_node, selective_sync_type: 'namespaces', namespaces: [create(:group)]) }

      it 'logs an event to the Geo event log when adding namespace restrictions' do
        service = described_class.new(restricted_geo_node, namespace_ids: namespace_ids)

        expect { service.execute }.to change(Geo::RepositoriesChangedEvent, :count).by(1)
      end

      it 'does not log an event to the Geo event log when removing namespace restrictions' do
        service = described_class.new(restricted_geo_node, namespace_ids: '')

        expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
      end

      it 'does not log an event to the Geo event log when node is a primary node' do
        primary.update!(selective_sync_type: 'namespaces')
        service = described_class.new(primary, namespace_ids: namespace_ids)

        expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
      end
    end

    context 'selective sync by shards' do
      let(:restricted_geo_node) { create(:geo_node, selective_sync_type: 'shards', selective_sync_shards: ['default']) }

      it 'logs an event to the Geo event log when adding shard restrictions' do
        service = described_class.new(restricted_geo_node, selective_sync_shards: %w[default broken])

        expect { service.execute }.to change(Geo::RepositoriesChangedEvent, :count).by(1)
      end

      it 'does not log an event to the Geo event log when removing shard restrictions' do
        service = described_class.new(restricted_geo_node, selective_sync_shards: [])

        expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
      end

      it 'does not log an event to the Geo event log when node is a primary node' do
        primary.update!(selective_sync_type: 'shards')
        service = described_class.new(primary, selective_sync_shards: %w[default broken'])

        expect { service.execute }.not_to change(Geo::RepositoriesChangedEvent, :count)
      end
    end
  end
end
