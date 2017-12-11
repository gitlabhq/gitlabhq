require 'spec_helper'

describe Geo::LfsObjectDeletedEventStore do
  set(:secondary_node) { create(:geo_node) }
  let(:lfs_object) { create(:lfs_object, :with_file, oid: 'b68143e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a00004') }

  subject(:event_store) { described_class.new(lfs_object) }

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::LfsObjectDeletedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when LFS object is not on a local store' do
        allow(lfs_object).to receive(:local_store?).and_return(false)

        expect { event_store.create }.not_to change(Geo::LfsObjectDeletedEvent, :count)
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::LfsObjectDeletedEvent, :count)
      end

      it 'creates a LFS object deleted event' do
        expect { event_store.create }.to change(Geo::LfsObjectDeletedEvent, :count).by(1)
      end

      it 'tracks LFS object attributes' do
        event_store.create

        event = Geo::LfsObjectDeletedEvent.last

        expect(event).to have_attributes(
          lfs_object_id: lfs_object.id,
          oid: lfs_object.oid,
          file_path: 'b6/81/43e6463773b1b6c6fd009a76c32aeec041faff32ba2ed42fd7f708a00004'
        )
      end

      it 'logs an error message when event creation fail' do
        invalid_lfs_object = create(:lfs_object)
        event_store = described_class.new(invalid_lfs_object)

        expected_message = {
          class: "Geo::LfsObjectDeletedEventStore",
          lfs_object_id: invalid_lfs_object.id,
          file_path: nil,
          message: "Lfs object deleted event could not be created",
          error: "Validation failed: File path can't be blank"
        }

        expect(Gitlab::Geo::Logger).to receive(:error)
          .with(expected_message).and_call_original

        event_store.create
      end
    end
  end
end
