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
    # Temporairy conditional, needed to move artifacts to their own table,
    # but keeping compat with Ci::Build for the time being
    job = job.build if job.respond_to?(:build)

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
    File.join(job.created_at.utc.strftime('%Y_%m'), job.project_id.to_s, job.id.to_s)
  end
end
