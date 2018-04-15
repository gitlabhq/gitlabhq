require 'spec_helper'

describe Gitlab::Geo::LfsDownloader, :geo do
  let(:lfs_object) { create(:lfs_object) }

  context '#execute' do
    context 'with LFS object' do
      it 'returns a FileDownloader::Result object' do
        downloader = described_class.new(:lfs, lfs_object.id)
        result = Gitlab::Geo::Transfer::Result.new(success: true, bytes_downloaded: 1)

        allow_any_instance_of(Gitlab::Geo::LfsTransfer)
          .to receive(:download_from_primary).and_return(result)

        expect(downloader.execute).to be_a(Gitlab::Geo::FileDownloader::Result)
      end
    end

    context 'with unknown job artifact' do
      let(:downloader) { described_class.new(:lfs, 10000) }

      it 'returns a FileDownloader::Result object' do
        expect(downloader.execute).to be_a(Gitlab::Geo::FileDownloader::Result)
      end

      it 'returns a result indicating a failure before a transfer was attempted' do
        expect(downloader.execute.failed_before_transfer).to be_truthy
      end
    end
  end
end
