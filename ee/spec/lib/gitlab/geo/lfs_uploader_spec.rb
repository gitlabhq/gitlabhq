require 'spec_helper'

describe Gitlab::Geo::LfsUploader, :geo do
  context '#execute' do
    subject { uploader.execute }

    context 'when the LFS object exists' do
      let(:uploader) { described_class.new(lfs_object.id, message) }

      before do
        expect(LfsObject).to receive(:find_by).with(id: lfs_object.id).and_return(lfs_object)
      end

      context 'when the LFS object has a file' do
        let(:lfs_object) { create(:lfs_object, :with_file) }
        let(:message) { { checksum: lfs_object.oid } }

        context 'when the message checksum matches the LFS object oid' do
          it 'returns the file in a success hash' do
            expect(subject).to eq(code: :ok, message: 'Success', file: lfs_object.file)
          end
        end

        context 'when the message checksum does not match the LFS object oid' do
          let(:message) { { checksum: 'foo' } }

          it 'returns an error hash' do
            expect(subject).to include(code: :not_found, message: "LFS object not found")
          end
        end
      end

      context 'when the LFS object does not have a file' do
        let(:lfs_object) { create(:lfs_object) }
        let(:message) { { checksum: lfs_object.oid } }

        it 'returns an error hash' do
          expect(subject).to include(code: :not_found, geo_code: 'FILE_NOT_FOUND', message: match(/LfsObject #\d+ file not found/))
        end

        it 'logs the missing file' do
          expect(uploader).to receive(:log_error).with("Could not upload LFS object because it does not have a file", id: lfs_object.id)

          subject
        end
      end
    end

    context 'when the LFS object does not exist' do
      let(:uploader) { described_class.new(10000, {}) }

      it 'returns an error hash' do
        expect(subject).to eq(code: :not_found, message: 'LFS object not found')
      end
    end
  end
end
