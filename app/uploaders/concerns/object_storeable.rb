module ObjectStoreable
  extend ActiveSupport::Concern

  module ClassMethods
    def use_object_store?
      @storage_options.object_store.enabled
    end

    def storage_options(options)
      @storage_options = options

      class_eval do
        storage use_object_store? ? :fog : :file
      end
    end
  end

  def fog_directory
    return super unless use_object_store?

    @storage_options.bucket
  end

  # Override the credentials
  def fog_credentials
    return super unless use_object_store?

    {
      provider:              @storage_options.provider,
      aws_access_key_id:     @storage_options.access_key_id,
      aws_secret_access_key: @storage_options.secret_access_key,
      region:                @storage_options.region,
      endpoint:              @storage_options.endpoint,
      path_style:            true
    }
  end

  def fog_public
    false
  end

  def use_object_store?
    @storage_options.object_store.enabled
  end

  def move_to_store
    !use_object_store?
  end

  def move_to_cache
    !use_object_store?
  end

  def use_file
    if use_object_store?
      return yield path
    end

    begin
      cache_stored_file!
      yield cache_path
    ensure
      cache_storage.delete_dir!(cache_path(nil))
    end
  end

  def upload_authorize
    self.cache_id = CarrierWave.generate_cache_id
    self.original_filename = SecureRandom.hex

    result = { TempPath: cache_path }

    use_cache_object_storage do
      expire_at = ::Fog::Time.now + fog_authenticated_url_expiration
      result[:ObjectStore] = {
        ObjectID: cache_name,
        StoreURL: storage.connection.put_object_url(
          fog_directory, cache_path, expire_at)
      }
    end

    result
  end

  def cache!(new_file = nil)
    unless retrive_uploaded_file!(new_file&.object_id, new_file.original_filename)
      super
    end
  end

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
