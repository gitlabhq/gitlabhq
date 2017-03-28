module ObjectStoreable
  extend ActiveSupport::Concern

  module ClassMethods
    def use_object_store?
      @storage_options.object_store.enabled
    end

    def storage_options(options)
      @storage_options = options

      class_eval do
        storage @storage_options.object_store.enabled ? :fog : :file
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
      path_style:            true
    }
  end

  def fog_public
    false
  end

  def use_object_store?
    @storage_options.object_store.enabled
  end
end
