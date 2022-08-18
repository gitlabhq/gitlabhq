# frozen_string_literal: true

def log_deprecations?
  via_env_var = Gitlab::Utils.to_boolean(ENV['GITLAB_LOG_DEPRECATIONS'])
  # enable by default during development unless explicitly turned off
  via_env_var.nil? ? Rails.env.development? : via_env_var
end

# Add `:notify` behavior only if not already added.
#
# See https://github.com/Shopify/deprecation_toolkit/blob/1d0e6f5b99785806f715ce2e9a13dc50f453d1e1/lib/deprecation_toolkit.rb#L21
def add_notify_behavior
  notify = ActiveSupport::Deprecation::DEFAULT_BEHAVIORS.fetch(:notify)
  behaviors = ActiveSupport::Deprecation.behavior

  return if behaviors.find { |behavior| behavior == notify }

  ActiveSupport::Deprecation.behavior = behaviors << notify
end

if log_deprecations?
  # Log deprecation warnings emitted through Kernel#warn, such as from gems or
  # the Ruby VM.
  actions = {
    /.+is deprecated$/ => lambda do |warning|
      Gitlab::DeprecationJsonLogger.info(message: warning.strip, source: 'ruby')
      # Returning :default means we continue emitting this to stderr as well.
      :default
    end
  }

  Warning.process('', actions)

  # We may have silenced deprecations warnings in 00_deprecations.rb on production.
  # Unsilence them again.
  ActiveSupport::Deprecation.silenced = false

  # If we want to consume emitted warnings from Rails we need to attach a notifier first.
  add_notify_behavior

  # Log deprecation warnings emitted from Rails (see ActiveSupport::Deprecation).
  ActiveSupport::Notifications.subscribe('deprecation.rails') do |name, start, finish, id, payload|
    Gitlab::DeprecationJsonLogger.info(message: payload[:message].strip, source: 'rails')
  end
end
