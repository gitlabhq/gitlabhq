class JobArtifactUploader < ArtifactUploader
  def initialize(artifact, _field)
    @artifact = artifact
  end

  def size
    return super unless @artifact.size

    @artifact.size
  end

  private

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(job.project_id.to_s)
  end

  def default_path
    creation_date = job.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, job.id.to_s, @artifact.id.to_s)
  end

  def job
    @artifact.job
  end
end
