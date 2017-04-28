module SentryHelper
  def sentry_enabled?
    Gitlab::Sentry.enabled?
  end

  def sentry_context
    Gitlab::Sentry.context(current_user)
  end

  def clientside_sentry_enabled?
    current_application_settings.clientside_sentry_enabled
  end

  delegate :clientside_sentry_dsn, to: :current_application_settings
end
