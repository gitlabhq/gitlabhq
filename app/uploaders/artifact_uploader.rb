class ArtifactUploader < GitlabUploader
  storage :file

  attr_reader :job, :field

  def self.local_artifacts_store
    Gitlab.config.artifacts.path
  end

  def initialize(job, field)
    @job, @field = job, field
  end

  def store_dir
    deprecated_local_path || default_local_path
  end

  def cache_dir
    File.join(self.class.local_artifacts_store, 'tmp/cache')
  end

  def deprecated_local_path
    return unless job.artifacts_storage_undefined?

    @deprecated_local_path ||= deprecated_paths.find do |artifact_path|
      File.directory?(File.join(self.class.local_artifacts_store, artifact_path))
    end
  end

  def migrate!
    return unless deprecated_local_path
    return unless default_local_path == deprecated_local_path

    FileUtils.move(deprecated_local_path, default_local_path, force: true)
  end

  def default_local_path
    File.join(self.class.local_artifacts_store, default_path)
  end

  def default_path
    File.join("project-#{job.project_id.to_s}", "pipeline-#{job.commit_id.to_s}", "job-#{id.to_s}")
  end

  ##
  # Deprecated
  #
  # This contains a hotfix for CI build data integrity, see #4246
  #
  # This method is used by `ArtifactUploader` to create a store_dir.
  # Warning: Uploader uses it after AND before file has been stored.
  #
  # This method returns old path to artifacts only if it already exists.
  #
  def deprecated_paths
    [
      File.join(created_at.utc.strftime('%Y_%m'), job.project_id.to_s, id.to_s),
      the_project&.ci_id && File.join(created_at.utc.strftime('%Y_%m'), the_project.ci_id.to_s, id.to_s),
    ].compact
  end

  def the_project
    job.project || job.unscoped_project
  end
end
