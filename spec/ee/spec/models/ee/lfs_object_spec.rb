require 'spec_helper'

describe LfsObject do
  describe '#local_store?' do
    it 'returns true when file_store is nil' do
      subject.file_store = nil

      expect(subject.local_store?).to eq true
    end

    it 'returns true when file_store is equal to LfsObjectUploader::LOCAL_STORE' do
      subject.file_store = LfsObjectUploader::LOCAL_STORE

      expect(subject.local_store?).to eq true
    end

    it 'returns false whe file_store is equal to LfsObjectUploader::REMOTE_STORE' do
      subject.file_store = LfsObjectUploader::REMOTE_STORE

      expect(subject.local_store?).to eq false
    end
  end

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
