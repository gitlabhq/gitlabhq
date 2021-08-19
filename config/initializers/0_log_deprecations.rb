# frozen_string_literal: true

def log_deprecations?
  via_env_var = Gitlab::Utils.to_boolean(ENV['GITLAB_LOG_DEPRECATIONS'])
  # enable by default during development unless explicitly turned off
  via_env_var.nil? ? Rails.env.development? : via_env_var
end

if log_deprecations?
  # Log deprecation warnings emitted through Kernel#warn, such as from gems or
  # the Ruby VM.
  Warning.process(/.+is deprecated$/) do |warning|
    Gitlab::DeprecationJsonLogger.info(message: warning.strip, source: 'ruby')
    # Returning :default means we continue emitting this to stderr as well.
    :default
  end

  # Log deprecation warnings emitted from Rails (see ActiveSupport::Deprecation).
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |name, start, finish, id, payload|
    Gitlab::DeprecationJsonLogger.info(message: payload[:message].strip, source: 'rails')
  end
end
