class JobArtifactUploader < GitlabUploader
  storage :file

  def self.local_store_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_store_path, 'tmp/uploads/')
  end

  def size
    return super if model.size.nil?

    model.size
  end

  def store_dir
    default_local_path
  end

  def cache_dir
    File.join(self.class.local_store_path, 'tmp/cache')
  end

  def work_dir
    File.join(self.class.local_store_path, 'tmp/work')
  end

  def open
    File.open(path, "rb")
  end

  private

  def default_local_path
    File.join(self.class.local_store_path, default_path)
  end

  def default_path
    creation_date = model.created_at.utc.strftime('%Y_%m_%d')

    File.join(disk_hash[0..1], disk_hash[2..3], disk_hash,
              creation_date, model.job_id.to_s, model.id.to_s)
  end

  def disk_hash
    @disk_hash ||= Digest::SHA2.hexdigest(model.project_id.to_s)
  end
end
