class JobArtifactUploader < GitlabUploader
  storage :file

  def self.local_artifacts_store
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_artifacts_store, 'tmp/uploads/')
  end

  def initialize(artifact, _field)
    @artifact = artifact
  end

  def size
    return super if @artifact.size.nil?

    @artifact.size
  end

  def store_dir
    File.join(self.class.local_artifacts_store, default_path)
  end

  private

  def default_path
    creation_date = @artifact.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, @artifact.job_id.to_s, @artifact.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(@artifact.project_id.to_s)
  end
end
