class LegacyArtifactUploader < GitlabUploader
  storage :file

  def self.local_store_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_store_path, 'tmp/uploads/')
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

  private

  def default_local_path
    File.join(self.class.local_store_path, default_path)
  end

  def default_path
    File.join(model.created_at.utc.strftime('%Y_%m'), model.project_id.to_s, model.id.to_s)
  end
end
