require 'spec_helper'

describe Gitlab::Geo::JobArtifactTransfer, :geo do
  set(:job_artifact) { create(:ci_job_artifact, :archive) }

  context '#initialize' do
    it 'sets file_type to :ci_trace' do
      expect(described_class.new(job_artifact).file_type).to eq(:job_artifact)
    end

    it 'sets file_id to the job artifact ID' do
      expect(described_class.new(job_artifact).file_id).to eq(job_artifact.id)
    end

    it 'sets filename to job artifact default_path' do
      expect(described_class.new(job_artifact).filename).to eq(job_artifact.file.path)
      expect(job_artifact.file.path).to be_present
    end

    it 'sets request_data with file_id and file_type' do
      expect(described_class.new(job_artifact).request_data).to eq(id: job_artifact.id)
    end
  end
end
