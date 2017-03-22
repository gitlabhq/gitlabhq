class ArtifactUploader < GitlabUploader
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

  def self.object_store_options
    Gitlab.config.artifacts.object_store
  end

  storage object_store_options.enabled ? :fog : :file

  def initialize(job, field)
    @job, @field = job, field
  end

  def store_dir
    File.join(self.class.artifacts_path, job.artifacts_path)
  end

  def cache_dir
    File.join(self.class.artifacts_cache_path, job.artifacts_path)
  end

  def fog_directory
    return super unless use_object_store?

    self.class.object_store_options.bucket
  end

  # Override the credentials
  def fog_credentials
    return super unless use_object_store?

    {
      provider:              object_store_options.provider,
      aws_access_key_id:     object_store_options.access_key_id,
      aws_secret_access_key: object_store_options.secret_access_key,
      region:                object_store_options.region,
      path_style:            true
    }
  end

  def filename
    file.try(:filename)
  end

  def exists?
    file.try(:exists?)
  end

  private

  def object_store_options
    self.class.object_store_options
  end

  def use_object_store?
    object_store_options.enabled
  end
end
