require 'spec_helper'

describe Geo::HashedStorageMigratedEventStore do
  let(:project) { create(:project, path: 'bar') }
  set(:secondary_node) { create(:geo_node) }
  let(:old_disk_path) { "#{project.namespace.full_path}/foo" }
  let(:old_wiki_disk_path) { "#{old_disk_path}.wiki" }

  subject(:event_store) { described_class.new(project, old_storage_version: nil, old_disk_path: old_disk_path, old_wiki_disk_path: old_wiki_disk_path) }

  describe '#create' do
    before do
      TestEnv.clean_test_path
    end

    it 'does not create an event when not running on a primary node' do
      allow(Gitlab::Geo).to receive(:primary?) { false }

      expect { event_store.create }.not_to change(Geo::HashedStorageMigratedEvent, :count)
    end

    context 'when running on a primary node' do
      before do
        allow(Gitlab::Geo).to receive(:primary?) { true }
      end

      it 'does not create an event when there are no secondary nodes' do
        allow(Gitlab::Geo).to receive(:secondary_nodes) { [] }

        expect { subject.create }.not_to change(Geo::HashedStorageMigratedEvent, :count)
      end

      it 'creates a hashed migration event' do
        expect { event_store.create }.to change(Geo::HashedStorageMigratedEvent, :count).by(1)
      end

      it 'tracks project attributes' do
        event_store.create

        event = Geo::HashedStorageMigratedEvent.last

        expect(event).to have_attributes(
          repository_storage_name: project.repository_storage,
          old_storage_version: nil,
          new_storage_version: project.storage_version,
          old_disk_path: old_disk_path,
          new_disk_path: project.disk_path,
          old_wiki_disk_path: old_wiki_disk_path,
          new_wiki_disk_path: project.wiki.disk_path
        )
      end
    end
  end
end
