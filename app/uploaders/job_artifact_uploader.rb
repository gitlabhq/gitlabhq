class JobArtifactUploader < ObjectStoreUploader
  storage_options Gitlab.config.artifacts

  def self.local_store_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_artifacts_store, 'tmp/uploads/')
  end

  def size
    return super if subject.size.nil?

    subject.size
  end

  private

  def default_path
    creation_date = subject.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, subject.job_id.to_s, subject.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(subject.project_id.to_s)
  end
end
