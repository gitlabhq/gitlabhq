class ArtifactUploader < GitlabUploader
  storage Gitlab.config.artifacts.object_store ? :fog : :file

  attr_accessor :job, :field

  def self.artifacts_path
    Gitlab.config.artifacts.path
  end

  def self.artifacts_upload_path
    File.join(self.artifacts_path, 'tmp/uploads/')
  end

  def self.artifacts_cache_path
    File.join(self.artifacts_path, 'tmp/cache/')
  end

  def initialize(job, field)
    @job, @field = job, field
  end

  def store_dir
    File.join(self.class.artifacts_path, job.artifacts_path)
  end

  def cache_dir
    File.join(self.class.artifacts_cache_path, job.artifacts_path)
  end

  def filename
    file.try(:filename)
  end

  def exists?
    file.try(:exists?)
  end
end
