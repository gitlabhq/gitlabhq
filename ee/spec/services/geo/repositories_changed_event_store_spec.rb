require 'spec_helper'

describe Geo::RepositoriesChangedEventStore do
  let(:geo_node) { create(:geo_node) }

  subject { described_class.new(geo_node) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { subject.create }.not_to change(Geo::RepositoriesChangedEvent, :count)
    end

    it 'creates a repositories changed event when running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { true }

      expect { subject.create }.to change(Geo::RepositoriesChangedEvent, :count).by(1)
    end
  end
end
