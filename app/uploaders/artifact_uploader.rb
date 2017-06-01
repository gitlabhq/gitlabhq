class ArtifactUploader < ObjectStoreUploader
  attr_reader :subject, :field

  storage_options Gitlab.config.artifacts

  def self.local_artifacts_store
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_artifacts_store, 'tmp/uploads/')
  end

  def initialize(subject, field)
    @subject = subject
    @field = field
  end

  def store_dir
    if file_storage?
      default_local_path
    else
      default_path
    end
  end

  def cache_dir
    if file_cache_storage?
      File.join(self.class.local_artifacts_store, 'tmp/cache')
    else
      'tmp/cache'
    end
  end

  private

  def default_local_path
    File.join(self.class.local_artifacts_store, default_path)
  end

  def default_path
    File.join(subject.created_at.utc.strftime('%Y_%m'), subject.project_id.to_s, subject.id.to_s)
  end
end
