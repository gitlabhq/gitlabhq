class ArtifactUploader < GitlabUploader
  storage :file

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
    default_local_path
  end

  def cache_dir
    File.join(self.class.local_artifacts_store, 'tmp/cache')
  end

  def work_dir
    File.join(self.class.local_artifacts_store, 'tmp/work')
  end

  private

  def default_local_path
    File.join(self.class.local_artifacts_store, default_path)
  end

  def default_path
    File.join(job.project_id.to_s,
              job.created_at.utc.strftime('%Y_%m'),
              job.id.to_s)
  end
end
