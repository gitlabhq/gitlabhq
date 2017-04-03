class ArtifactUploader < GitlabUploader
  include ObjectStoreable

  storage_options Gitlab.config.artifacts

  def self.artifacts_path
    if object_store_options.enabled
      ""
    else
      storage_options.path + "/"
    end
  end

  def artifacts_path
    self.class.artifacts_path
  end

  def self.artifacts_upload_path
    self.artifacts_path + 'tmp/uploads'
  end

  def self.artifacts_cache_path
    self.artifacts_path + 'tmp/cache'
  end

  attr_accessor :job, :field

  def self.object_store_options
    Gitlab.config.artifacts.object_store
  end

  if object_store_options.enabled
    storage :fog
    #cache_storage :fog
  else
    storage :file
    #cache_storage :file
  end

  def initialize(job, field)
    @job, @field = job, field
  end

  def store_dir
    self.class.artifacts_path + job.artifacts_path
  end

  def cache_dir
    self.class.artifacts_cache_path + job.artifacts_path
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
      endpoint:              object_store_options.endpoint,
      path_style:            true
    }
  end

  def filename
    file.try(:filename)
  end

  def exists?
    file.try(:exists?)
  end

  def fog_public
    false
  end

  def upload_authorize
    result = { TempPath: ArtifactUploader.artifacts_upload_path }

    if use_object_store?
      path = File.join('tmp', 'cache', 'upload', SecureRandom.hex)
      expire_at = ::Fog::Time.now + fog_authenticated_url_expiration
      result[:UploadPath] = path
      result[:UploadURL] = storage.connection.put_object_url(
        fog_directory, path, expire_at)
    end

    result
  end

  def retrive_uploaded!(path)
    CarrierWave::Storage::Fog::File.new(self, storage, path)
  end

  def upload_cache_path(path = nil)
    File.join(cache_dir, path)
  end

  private

  def object_store_options
    self.class.object_store_options
  end

  def use_object_store?
    object_store_options.enabled
  end
end
