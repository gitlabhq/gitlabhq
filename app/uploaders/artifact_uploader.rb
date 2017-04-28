class ArtifactUploader < GitlabUploader
  include ObjectStoreable

  storage_options Gitlab.config.artifacts

  attr_reader :job, :field

  def initialize(job, field)
    @job, @field = job, field
  end

  def store_dir
    if remote_cache_storage?
      job.artifacts_path
    else
      File.join(storage_options.artifacts_path, job.artifacts_path)
    end
  end

  def cache_dir
    if remote_cache_storage?
      File.join('tmp/cache', job.artifacts_path)
    else
      File.join(storage_options.artifacts_path, 'tmp/cache', job.artifacts_path)
    end
  end

  def exists?
    file.try(:exists?)
  end

  def upload_authorize
    self.cache_id = CarrierWave.generate_cache_id
    self.original_filename = SecureRandom.hex

    result = { TempPath: cache_path }

    use_cache_object_storage do
      expire_at = ::Fog::Time.now + fog_authenticated_url_expiration
      result[:UploadPath] = cache_name
      result[:UploadURL] = storage.connection.put_object_url(
        fog_directory, cache_path, expire_at)
    end

    result
  end

  def cache!(new_file = nil)
    unless retrive_uploaded_file!(new_file&.upload_path, new_file.original_filename)
      super
    end
  end

  private

  def cache_storage
    if @use_storage_for_cache || cached? && remote_file?
      storage
    else
      super
    end
  end

  def retrive_uploaded_file!(identifier, filename)
    return unless identifier
    return unless filename
    return unless use_object_store?

    @use_storage_for_cache = true

    retrieve_from_cache!(identifier)
    @filename = filename
  ensure
    @use_storage_for_cache = false
  end
end
