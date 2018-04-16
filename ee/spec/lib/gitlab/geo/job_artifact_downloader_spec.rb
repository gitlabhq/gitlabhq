require 'spec_helper'

describe Gitlab::Geo::JobArtifactDownloader, :geo do
  let(:job_artifact) { create(:ci_job_artifact) }

  context '#execute' do
    context 'with job artifact' do
      it 'returns a FileDownloader::Result object' do
        downloader = described_class.new(:job_artifact, job_artifact.id)
        result = Gitlab::Geo::Transfer::Result.new(success: true, bytes_downloaded: 1)

        allow_any_instance_of(Gitlab::Geo::JobArtifactTransfer)
          .to receive(:download_from_primary).and_return(result)

        expect(downloader.execute).to be_a(Gitlab::Geo::FileDownloader::Result)
      end
    end

    context 'with unknown job artifact' do
      let(:downloader) { described_class.new(:job_artifact, 10000) }

      it 'returns a FileDownloader::Result object' do
        expect(downloader.execute).to be_a(Gitlab::Geo::FileDownloader::Result)
      end

      it 'returns a result indicating a failure before a transfer was attempted' do
        expect(downloader.execute.failed_before_transfer).to be_truthy
      end
    end
  end
end
