class DirectUploadsValidator
  SUPPORTED_DIRECT_UPLOAD_PROVIDERS = %w(Google AWS).freeze

  ValidationError = Class.new(StandardError)

  def verify!(object_store)
    return unless object_store.enabled
    return unless object_store.direct_upload
    return if SUPPORTED_DIRECT_UPLOAD_PROVIDERS.include?(object_store.connection&.provider.to_s)

    raise ValidationError, "Only #{SUPPORTED_DIRECT_UPLOAD_PROVIDERS.join(',')} are supported as a object storage provider when 'direct_upload' is used"
  end
end

DirectUploadsValidator.new.tap do |validator|
  [Gitlab.config.artifacts, Gitlab.config.uploads, Gitlab.config.lfs].each do |uploader|
    validator.verify!(uploader.object_store)
  end
end
