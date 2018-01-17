require 'spec_helper'

describe Geo::HashedStorageAttachmentsEventStore do
  let(:project) { create(:project, :hashed, path: 'bar') }
  let(:attachments_event) { build(:geo_hashed_storage_attachments_event, project: project) }
  set(:secondary_node) { create(:geo_node) }
  let(:old_attachments_path) { attachments_event.old_attachments_path }
  let(:new_attachments_path) {attachments_event.new_attachments_path }

  subject(:event_store) { described_class.new(project, old_storage_version: 1, new_storage_version: 2, old_attachments_path: old_attachments_path, new_attachments_path: new_attachments_path) }

  before do
    TestEnv.clean_test_path
  end

  describe '#create' do
    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::HashedStorageAttachmentsEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { event_store.create }.not_to change(Geo::HashedStorageAttachmentsEvent, :count)
      end

      it 'creates a attachment migration event' do
        expect { event_store.create }.to change(Geo::HashedStorageAttachmentsEvent, :count).by(1)
      end

      it 'tracks project attributes' do
        event_store.create

        event = Geo::HashedStorageAttachmentsEvent.last

        expect(event).to have_attributes(
          old_attachments_path: old_attachments_path,
          new_attachments_path: new_attachments_path
        )
      end
    end
  end
end
