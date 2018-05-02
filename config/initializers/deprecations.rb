deprecator = ActiveSupport::Deprecation.new('11.0', 'GitLab')

if Gitlab.dev_env_or_com?
  ActiveSupport::Deprecation.deprecate_methods(Gitlab::GitalyClient::StorageSettings, :legacy_disk_path, deprecator: deprecator)
end
