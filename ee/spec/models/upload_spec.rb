require 'spec_helper'

describe Upload do
  describe '#destroy' do
    subject { create(:upload, checksum: '8710d2c16809c79fee211a9693b64038a8aae99561bc86ce98a9b46b45677fe4') }

    context 'when running in a Geo primary node' do
      set(:primary) { create(:geo_node, :primary) }
      set(:secondary) { create(:geo_node) }

      it 'logs an event to the Geo event log' do
        expect { subject.destroy }.to change(Geo::UploadDeletedEvent, :count).by(1)
      end
    end
  end
end
