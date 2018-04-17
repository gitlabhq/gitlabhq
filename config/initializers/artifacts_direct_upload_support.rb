artifacts_object_store = Gitlab.config.artifacts.object_store

if artifacts_object_store.enabled &&
    artifacts_object_store.direct_upload &&
    artifacts_object_store.connection&.provider.to_s != 'Google'
  raise "Only 'Google' is supported as a object storage provider when 'direct_upload' of artifacts is used"
end
