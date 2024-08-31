# frozen_string_literal: true

if Rails.env.development? || ENV['GITLAB_LEGACY_PATH_LOG_MESSAGE']
  deprecator = ActiveSupport::Deprecation.new('11.0', 'GitLab')

  deprecator.behavior = ->(message, callstack) {
    Gitlab::AppLogger.warn("#{message}: #{callstack[1..20].join}")
  }

  deprecator.deprecate_methods(Gitlab::GitalyClient::StorageSettings, :legacy_disk_path)
end
