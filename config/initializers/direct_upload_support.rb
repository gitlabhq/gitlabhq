class DirectUploadsValidator
  SUPPORTED_DIRECT_UPLOAD_PROVIDERS = %w(Google AWS).freeze

  ValidationError = Class.new(StandardError)

  def verify!(uploader_type, object_store)
    return unless object_store.enabled
    return unless object_store.direct_upload

    raise ValidationError, "Object storage is configured for '#{uploader_type}', but the 'connection' section is missing" unless object_store.key?('connection')

    provider = object_store.connection&.provider.to_s

    raise ValidationError, "No provider configured for '#{uploader_type}'. #{supported_provider_text}" if provider.blank?

    return if SUPPORTED_DIRECT_UPLOAD_PROVIDERS.include?(provider)

    raise ValidationError, "Object storage provider '#{provider}' is not supported " \
                           "when 'direct_upload' is used for '#{uploader_type}'. #{supported_provider_text}"
  end

  def supported_provider_text
    "Only #{SUPPORTED_DIRECT_UPLOAD_PROVIDERS.join(', ')} are supported."
  end
end

DirectUploadsValidator.new.tap do |validator|
  CONFIGS = {
    artifacts: Gitlab.config.artifacts,
    uploads: Gitlab.config.uploads,
    lfs: Gitlab.config.lfs
  }.freeze

  CONFIGS.each do |uploader_type, uploader|
    validator.verify!(uploader_type, uploader.object_store)
  end
end
