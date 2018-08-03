require 'spec_helper'

describe Projects::HashedStorage::MigrateAttachmentsService do
  let(:project) { create(:project, storage_version: 1) }
  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }
  let(:old_attachments_path) { legacy_storage.disk_path }
  let(:new_attachments_path) { hashed_storage.disk_path }
  let(:service) { described_class.new(project, old_attachments_path) }

  describe '#execute' do
    set(:primary) { create(:geo_node, :primary) }
    set(:secondary) { create(:geo_node) }

    context 'on success' do
      before do
        TestEnv.clean_test_path
        FileUtils.mkdir_p(File.join(FileUploader.root, old_attachments_path))
      end

      it 'returns true' do
        expect(service.execute).to be_truthy
      end

      it 'creates a Geo::HashedStorageAttachmentsEvent' do
        expect { service.execute }.to change(Geo::EventLog, :count).by(1)

        event = Geo::EventLog.first.event

        expect(event).to be_a(Geo::HashedStorageAttachmentsEvent)
        expect(event).to have_attributes(
          old_attachments_path: old_attachments_path,
          new_attachments_path: new_attachments_path
        )
      end
    end

    context 'on failure' do
      it 'does not create a Geo event when skipped' do
        expect { service.execute }.not_to change { Geo::EventLog.count }
      end

      it 'does not create a Geo event on failure' do
        expect(service).to receive(:move_folder!).and_raise(::Projects::HashedStorage::AttachmentMigrationError)
        expect { service.execute }.to raise_error(::Projects::HashedStorage::AttachmentMigrationError)
        expect(Geo::EventLog.count).to eq(0)
      end
    end
  end
end
