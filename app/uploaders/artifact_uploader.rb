class ArtifactUploader < GitlabUploader
  include ObjectStoreable

  attr_reader :job, :field

  def self.local_artifacts_store
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.local_artifacts_store, 'tmp/uploads/')
  end

  def initialize(job, field)
    @job, @field = job, field
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
      File.join(self.local_artifacts_store, 'tmp/cache')
    else
      'tmp/cache'
    end
  end

  def migrate!
    # TODO
  end

  private

  def default_local_path
    File.join(self.class.local_artifacts_store, default_path)
  end

  def default_path
    File.join(job.created_at.utc.strftime('%Y_%m'), job.project_id.to_s, job.id.to_s)
  end
end
