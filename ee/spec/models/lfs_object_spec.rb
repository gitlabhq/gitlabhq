require 'spec_helper'

describe LfsObject do
  describe '#destroy' do
    subject { create(:lfs_object, :with_file) }

    context 'when running in a Geo primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log' do
        expect { subject.destroy }.to change(Geo::LfsObjectDeletedEvent, :count).by(1)
      end
    end
  end
end
