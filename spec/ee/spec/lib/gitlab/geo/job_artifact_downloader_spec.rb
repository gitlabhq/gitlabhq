require 'spec_helper'

describe Gitlab::Geo::JobArtifactDownloader, :geo do
  let(:job_artifact) { create(:ci_job_artifact) }

  subject do
    described_class.new(:job_artifact, job_artifact.id)
  end

  context '#download_from_primary' do
    it 'with a job artifact' do
      allow_any_instance_of(Gitlab::Geo::JobArtifactTransfer)
        .to receive(:download_from_primary).and_return(100)

      expect(subject.execute).to eq(100)
    end

    it 'with an unknown job artifact' do
      expect(described_class.new(:job_artifact, 10000)).not_to receive(:download_from_primary)

      expect(subject.execute).to be_nil
    end
  end
end
