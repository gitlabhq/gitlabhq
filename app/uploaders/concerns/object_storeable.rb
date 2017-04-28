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

  def remote_file?
    file&.is_a?(CarrierWave::Storage::Fog::File)
  end

  def remote_storage?
    storage.is_a?(CarrierWave::Storage::Fog)
  end

  def remote_cache_storage?
    cache_storage.is_a?(CarrierWave::Storage::Fog)
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
end
