require 'spec_helper'
require 'rake_helper'

describe SystemCheck::Geo::FdwEnabledCheck, :geo do
  describe '#skip?' do
    subject { described_class.new.skip? }

    it 'skips when Geo is disabled' do
      allow(Gitlab::Geo).to receive(:enabled?) { false }

      is_expected.to be_truthy
    end

    it 'skips when Geo is enabled but its a primary node' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { false }

      is_expected.to be_truthy
    end

    it 'does not skip when Geo is enabled and its a secondary node' do
      allow(Gitlab::Geo).to receive(:enabled?) { true }
      allow(Gitlab::Geo).to receive(:secondary?) { true }

      is_expected.to be_falsey
    end
  end

  describe '#check?' do
    context 'with functional FDW environment', :geo_tracking_db do
      it 'returns true' do
        expect(subject.check?).to be_truthy
      end
    end
  end
end
