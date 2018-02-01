require 'spec_helper'

describe JobArtifactUploader do
  let(:store) { described_class::LOCAL_STORE }
  let(:job_artifact) { create(:ci_job_artifact, file_store: store) }
  let(:uploader) { described_class.new(job_artifact, :file) }

  describe '#open' do
    subject { uploader.open }

    context 'when trace is stored in Object storage' do
      before do
        allow(uploader).to receive(:file_storage?) { false }
        allow(uploader).to receive(:url) { 'http://object_storage.com/trace' }
      end

      it 'returns http io stream' do
        is_expected.to be_a(Gitlab::Ci::Trace::HttpIO)
      end
    end
  end
end
