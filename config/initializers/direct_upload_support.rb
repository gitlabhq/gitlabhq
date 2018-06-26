class DirectUploadsValidator
  SUPPORTED_DIRECT_UPLOAD_PROVIDERS = %w(Google AWS).freeze

  ValidationError = Class.new(StandardError)

  def verify_providers!(object_store)
    return unless object_store.enabled
    return unless object_store.direct_upload
    return if SUPPORTED_DIRECT_UPLOAD_PROVIDERS.include?(object_store.connection&.provider.to_s)

    raise ValidationError, "Only #{SUPPORTED_DIRECT_UPLOAD_PROVIDERS.join(',')} are supported as a object storage provider when 'direct_upload' is used"
  end

  def verify_config!(local_store, object_store)
    return if local_store.enabled

    raise ValidationError, "At least local_store or object_store has to be enabled" unless object_store.enabled
    raise ValidationError, "The object_store#direct_upload is required if local_store is not enabled" unless object_store.direct_upload
    raise ValidationError, "The object_store#background_upload is forbidden if local_store is not enabled" if object_store.background_upload
  end
end

DirectUploadsValidator.new.tap do |validator|
  [Gitlab.config.artifacts, Gitlab.config.uploads, Gitlab.config.lfs].each do |uploader|
    validator.verify_config!(uploader.object_store)
    validator.verify_providers!(uploader.object_store)
  end
end
