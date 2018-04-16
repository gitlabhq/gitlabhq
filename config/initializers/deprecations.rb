deprecator = ActiveSupport::Deprecation.new('11.0', 'GitLab')

if Gitlab.com? || Rails.env.development?
  ActiveSupport::Deprecation.deprecate_methods(Gitlab::GitalyClient::StorageSettings, :legacy_disk_path, deprecator: deprecator)
end
