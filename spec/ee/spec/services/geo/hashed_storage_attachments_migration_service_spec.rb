require 'spec_helper'

def base_path(storage)
  File.join(FileUploader.root, storage.disk_path)
end

describe Geo::HashedStorageAttachmentsMigrationService do
  let!(:project) { create(:project, :legacy_storage) }

  let(:legacy_storage) { Storage::LegacyProject.new(project) }
  let(:hashed_storage) { Storage::HashedProject.new(project) }

  let!(:upload) { Upload.find_by(path: file_uploader.upload_path) }
  let(:file_uploader) { build(:file_uploader, project: project) }
  let(:old_path) { File.join(base_path(legacy_storage), upload.path) }
  let(:new_path) { File.join(base_path(hashed_storage), upload.path) }

  subject(:service) do
    described_class.new(project.id,
                        old_attachments_path: legacy_storage.disk_path,
                        new_attachments_path: hashed_storage.disk_path)
  end

  describe '#execute' do
    context 'when succeeds' do
      it 'moves attachments to hashed storage layout' do
        expect(File.file?(old_path)).to be_truthy
        expect(File.file?(new_path)).to be_falsey
        expect(File.exist?(base_path(legacy_storage))).to be_truthy
        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(FileUtils).to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage)).and_call_original

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_truthy
        expect(File.exist?(base_path(legacy_storage))).to be_falsey
        expect(File.file?(old_path)).to be_falsey
        expect(File.file?(new_path)).to be_truthy
      end
    end

    context 'when original folder does not exist anymore' do
      before do
        FileUtils.rm_rf(base_path(legacy_storage))
      end

      it 'skips moving folders and go to next' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        service.execute

        expect(File.exist?(base_path(hashed_storage))).to be_falsey
        expect(File.file?(new_path)).to be_falsey
      end
    end

    context 'when target folder already exists' do
      before do
        FileUtils.mkdir_p(base_path(hashed_storage))
      end

      it 'raises AttachmentMigrationError' do
        expect(FileUtils).not_to receive(:mv).with(base_path(legacy_storage), base_path(hashed_storage))

        expect { service.execute }.to raise_error(::Geo::AttachmentMigrationError)
      end
    end
  end

  describe '#async_execute' do
    it 'starts the worker' do
      expect(Geo::HashedStorageAttachmentsMigrationWorker).to receive(:perform_async)

      service.async_execute
    end

    it 'returns job id' do
      allow(Geo::HashedStorageAttachmentsMigrationWorker).to receive(:perform_async).and_return('foo')

      expect(service.async_execute).to eq('foo')
    end
  end
end
