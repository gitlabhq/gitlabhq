require 'spec_helper'

describe Geo::UploadDeletedEventStore do
  set(:secondary_node) { create(:geo_node) }
  let(:upload) { create(:upload) }

  subject(:event_store) { described_class.new(upload) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::UploadDeletedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::UploadDeletedEvent, :count)
      end

      it 'creates an upload deleted event' do
        expect { event_store.create }.to change(Geo::UploadDeletedEvent, :count).by(1)
      end

      it 'does not create an event when the upload does not use local storage' do
        allow(upload).to receive(:local?).and_return(false)

        expect { event_store.create }.not_to change(Geo::UploadDeletedEvent, :count)
      end

      it 'tracks upload attributes' do
        event_store.create
        event = Geo::UploadDeletedEvent.last

        expect(event).to have_attributes(
          upload_id: upload.id,
          file_path: upload.path,
          model_id: upload.model_id,
          model_type: upload.model_type,
          uploader: upload.uploader
        )
      end
    end
  end
end
