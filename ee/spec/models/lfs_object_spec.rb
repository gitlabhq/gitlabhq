require 'spec_helper'

describe LfsObject do
  describe '#local_store?' do
    it 'returns true when file_store is nil' do
      subject.file_store = nil

      expect(subject.local_store?).to eq true
    end

    it 'returns true when file_store is equal to LfsObjectUploader::Store::LOCAL' do
      subject.file_store = LfsObjectUploader::Store::LOCAL

      expect(subject.local_store?).to eq true
    end

    it 'returns false whe file_store is equal to LfsObjectUploader::Store::REMOTE' do
      subject.file_store = LfsObjectUploader::Store::REMOTE

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

  describe '#schedule_background_upload' do
    before do
      stub_lfs_setting(enabled: true)
    end

    subject { create(:lfs_object, :with_file) }

    context 'when object storage is disabled' do
      before do
        stub_lfs_object_storage(enabled: false)
      end

      it 'does not schedule the migration' do
        expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

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
            expect(ObjectStorage::BackgroundMoveWorker)
              .to receive(:perform_async)
              .with('LfsObjectUploader', described_class.name, :file, kind_of(Numeric))
              .once

            subject
          end

          it 'schedules the model for migration once' do
            expect(ObjectStorage::BackgroundMoveWorker)
              .to receive(:perform_async)
              .with('LfsObjectUploader', described_class.name, :file, kind_of(Numeric))
              .once

            lfs_object = create(:lfs_object)
            lfs_object.file = fixture_file_upload(Rails.root + "spec/fixtures/dk.png", "`/png")
            lfs_object.save!
          end
        end

        context 'when is unlicensed' do
          before do
            stub_lfs_object_storage(background_upload: true, licensed: false)
          end

          it 'does not schedule the migration' do
            expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

            subject
          end
        end
      end

      context 'when background upload is disabled' do
        before do
          stub_lfs_object_storage(background_upload: false)
        end

        it 'schedules the model for migration' do
          expect(ObjectStorage::BackgroundMoveWorker).not_to receive(:perform_async)

          subject
        end
      end
    end
  end
end
