require 'spec_helper'
require 'rake_helper'

describe SystemCheck::Geo::FdwSchemaUpToDateCheck, :geo do
  describe '#skip?' do
    it 'skips when Geo is disabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { false }

      expect(subject.skip?).to be_truthy
      expect(subject.skip_reason).to eq('not a secondary node')
    end

    it 'skips when Geo is enabled but its a primary node' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      expect(subject.skip?).to be_truthy
      expect(subject.skip_reason).to eq('not a secondary node')
    end

    it 'skips when FDW is disabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { true }
      allow(Gitlab::Geo::Fdw).to receive(:enabled?) { false }

      expect(subject.skip?).to be_truthy
      expect(subject.skip_reason).to eq('foreign data wrapper is not configured')
    end

    it 'does not skip when Geo is enabled, its a secondary node and FDW is enabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { true }
      allow(Gitlab::Geo::Fdw).to receive(:enabled?) { true }

      expect(subject.skip?).to be_falsey
    end
  end

  context 'with functional FDW environment', :geo_tracking_db do
    it 'returns true' do
      expect(subject.check?).to be_truthy
    end
  end
end
