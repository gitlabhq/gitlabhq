class JobArtifactUploader < ArtifactUploader
  def initialize(artifact, _field)
    @artifact = artifact
  end

  def size
    return super if @artifact.size.nil?

    @artifact.size
  end

  private

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(@artifact.project_id.to_s)
  end

  def default_path
    creation_date = @artifact.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, @artifact.ci_job_id.to_s, @artifact.id.to_s)
  end
end
