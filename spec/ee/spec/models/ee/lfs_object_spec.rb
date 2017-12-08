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

  describe '#schedule_migration_to_object_storage' do
    before do
      stub_lfs_setting(enabled: true)
    end

    subject { create(:lfs_object, :with_file) }

    context 'when object storage is disabled' do
      before do
        stub_lfs_object_storage(enabled: false)
      end

      it 'does not schedule the migration' do
        expect(ObjectStorageUploadWorker).not_to receive(:perform_async)

        subject
      end
    end

    context 'when object storage is enabled' do
      context 'when background upload is enabled' do
        context 'when is licensed' do
          before do
            stub_lfs_object_storage(background_upload: true)
          end

          it 'schedules the model for migration' do
            expect(ObjectStorageUploadWorker).to receive(:perform_async).with('LfsObjectUploader', described_class.name, :file, kind_of(Numeric))

            subject
          end
        end

        context 'when is unlicensed' do
          before do
            stub_lfs_object_storage(background_upload: true, licensed: false)
          end

          it 'does not schedule the migration' do
            expect(ObjectStorageUploadWorker).not_to receive(:perform_async)

            subject
          end
        end
      end

      context 'when background upload is disabled' do
        before do
          stub_lfs_object_storage(background_upload: false)
        end

        it 'schedules the model for migration' do
          expect(ObjectStorageUploadWorker).not_to receive(:perform_async)

          subject
        end
      end
    end
  end
end
