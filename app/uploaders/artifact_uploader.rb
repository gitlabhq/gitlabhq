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
  else
    storage :file
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

  def exists?
    file.try(:exists?)
  end

  def fog_public
    false
  end

  def upload_authorize
    result = { TempPath: ArtifactUploader.artifacts_upload_path }

    use_cache_object_storage do
      self.cache_id = CarrierWave.generate_cache_id
      self.original_filename = SecureRandom.hex
      expire_at = ::Fog::Time.now + fog_authenticated_url_expiration
      result[:UploadPath] = cache_name
      result[:UploadURL] = storage.connection.put_object_url(
        fog_directory, cache_path, expire_at)
    end

    result
  end

  def upload_cache_path(path = nil)
    File.join(cache_dir, path)
  end

  def cache!(new_file = nil)
    use_cache_object_storage do
      retrieve_from_cache!(new_file.upload_path)
      @filename = new_file.original_filename
      store_path
      return
    end if new_file&.upload_path

    super
  end

  private

  def object_store_options
    self.class.object_store_options
  end

  def use_object_store?
    object_store_options.enabled
  end

  def cache_storage
    if @use_storage_for_cache
      storage
    else
      super
    end
  end

  def use_cache_object_storage
    return unless use_object_store?

    @use_storage_for_cache = true
    yield
  ensure
    @use_storage_for_cache = false
  end

  def move_to_store
    storage.is_a?(CarrierWave::Storage::File)
  end

  def move_to_cache
    cache_storage.is_a?(CarrierWave::Storage::File)
  end
end
