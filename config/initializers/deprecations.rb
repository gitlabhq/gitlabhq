if Rails.env.development? || ENV['GITLAB_LEGACY_PATH_LOG_MESSAGE']
  deprecator = ActiveSupport::Deprecation.new('11.0', 'GitLab')

  deprecator.behavior = -> (message, callstack) {
    Rails.logger.warn("#{message}: #{callstack[1..20].join}")
  }

  ActiveSupport::Deprecation.deprecate_methods(Gitlab::GitalyClient::StorageSettings, :legacy_disk_path, deprecator: deprecator)
end
