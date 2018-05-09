SUPPORTED_DIRECT_UPLOAD_PROVIDERS = %w(Google AWS).freeze

def verify_provider_support!(object_store)
  return unless object_store.enabled
  return unless object_store.direct_upload
  return if SUPPORTED_DIRECT_UPLOAD_PROVIDERS.include?(object_store.connection&.provider.to_s)

  raise "Only #{SUPPORTED_DIRECT_UPLOAD_PROVIDERS.join(',')} are supported as a object storage provider when 'direct_upload' is used"
end

verify_provider_support!(Gitlab.config.artifacts.object_store)
verify_provider_support!(Gitlab.config.uploads.object_store)
verify_provider_support!(Gitlab.config.lfs.object_store)
