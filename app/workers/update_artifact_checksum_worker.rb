class UpdateArtifactChecksumWorker
  include ApplicationWorker
  include ObjectStorageQueue

  def perform(job_artifact_id)
    Ci::JobArtifact.find_by(id: job_artifact_id).try do |job_artifact|
      job_artifact.set_checksum
      job_artifact.save!
    end
  end
end
