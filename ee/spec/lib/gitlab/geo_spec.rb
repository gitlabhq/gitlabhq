require 'spec_helper'

describe Gitlab::Geo, :geo do
  include ::EE::GeoHelpers

  set(:primary_node)   { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }

  describe 'current_node' do
    it 'returns a GeoNode instance' do
      expect(described_class.current_node).to eq(primary_node)
    end
  end

  describe 'primary_node' do
    it 'returns a GeoNode primary instance' do
      expect(described_class.primary_node).to eq(primary_node)
    end
  end

  describe 'primary?' do
    context 'when current node is a primary node' do
      it 'returns true' do
        expect(described_class.primary?).to be_truthy
      end

      it 'returns false when GeoNode is disabled' do
        allow(described_class).to receive(:enabled?) { false }

        expect(described_class.primary?).to be_falsey
      end
    end
  end

  describe 'primary_node_configured?' do
    context 'when current node is a primary node' do
      it 'returns true' do
        expect(described_class.primary_node_configured?).to be_truthy
      end

      it 'returns false when primary does not exist' do
        primary_node.destroy

        expect(described_class.primary_node_configured?).to be_falsey
      end
    end
  end

  describe 'secondary?' do
    context 'when current node is a secondary node' do
      before do
        stub_current_geo_node(secondary_node)
      end

      it 'returns true' do
        expect(described_class.secondary?).to be_truthy
      end

      it 'returns false when GeoNode is disabled' do
        allow(described_class).to receive(:enabled?) { false }

        expect(described_class.secondary?).to be_falsey
      end
    end
  end

  describe 'enabled?' do
    context 'when any GeoNode exists' do
      it 'returns true' do
        expect(described_class.enabled?).to be_truthy
      end
    end

    context 'when no GeoNode exists' do
      before do
        GeoNode.delete_all
      end

      it 'returns false' do
        expect(described_class.enabled?).to be_falsey
      end
    end

    context 'with RequestStore enabled', :request_store do
      it 'return false when no GeoNode exists' do
        GeoNode.delete_all

        expect(GeoNode).to receive(:exists?).once.and_call_original

        2.times { expect(described_class.enabled?).to be_falsey }
      end
    end
  end

  describe 'connected?' do
    context 'when there is a database issue' do
      it 'returns false when database connection is down' do
        allow(GeoNode).to receive(:connected?) { false }

        expect(described_class.connected?).to be_falsey
      end

      it 'returns false when the table does not exist' do
        allow(GeoNode).to receive(:table_exists?) { false }

        expect(described_class.connected?).to be_falsey
      end

      it 'returns false when MySQL is in use' do
        allow(Gitlab::Database).to receive(:postgresql?) { false }

        expect(described_class.connected?).to be_falsey
      end
    end
  end

  describe 'secondary?' do
    context 'when current node is secondary' do
      it 'returns true' do
        stub_current_geo_node(secondary_node)
        expect(described_class.secondary?).to be_truthy
      end
    end

    context 'current node is primary' do
      it 'returns false' do
        expect(described_class.secondary?).to be_falsey
      end
    end
  end

  describe 'license_allows?' do
    it 'returns true if license has Geo addon' do
      stub_licensed_features(geo: true)
      expect(described_class.license_allows?).to be_truthy
    end

    it 'returns false if license doesnt have Geo addon' do
      stub_licensed_features(geo: false)
      expect(described_class.license_allows?).to be_falsey
    end

    it 'returns false if no license is present' do
      allow(License).to receive(:current) { nil }
      expect(described_class.license_allows?).to be_falsey
    end
  end

  describe '.generate_access_keys' do
    it 'returns a public and secret access key' do
      keys = described_class.generate_access_keys

      expect(keys[:access_key].length).to eq(20)
      expect(keys[:secret_access_key].length).to eq(40)
    end
  end

  describe '.configure_cron_jobs!' do
    let(:manager) { double('cron_manager').as_null_object }

    before do
      allow(Gitlab::Geo::CronManager).to receive(:new) { manager }
    end

    it 'creates a cron watcher' do
      expect(manager).to receive(:create_watcher!)

      described_class.configure_cron_jobs!
    end

    it 'runs the cron manager' do
      expect(manager).to receive(:execute)

      described_class.configure_cron_jobs!
    end
  end

  describe '.repository_verification_enabled?' do
    context "when the feature flag hasn't been set" do
      it 'returns true' do
        expect(described_class.repository_verification_enabled?).to eq true
      end
    end

    context 'when the feature flag has been set' do
      context 'when the feature flag is set to enabled' do
        it 'returns true' do
          Feature.enable('geo_repository_verification')

          expect(described_class.repository_verification_enabled?).to eq true
        end
      end

      context 'when the feature flag is set to disabled' do
        it 'returns false' do
          Feature.disable('geo_repository_verification')

          expect(described_class.repository_verification_enabled?).to eq false
        end
      end
    end
  end
end
