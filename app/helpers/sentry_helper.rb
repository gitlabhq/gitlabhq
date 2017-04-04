module SentryHelper
  def sentry_enabled?
    Gitlab::Sentry.enabled?
  end

  def sentry_context
    Gitlab::Sentry.context(current_user)
  end

  def sentry_dsn_public
    sentry_dsn = ApplicationSetting.current.sentry_dsn

    return unless sentry_dsn

    uri = URI.parse(sentry_dsn)
    uri.password = nil
    uri.to_s
  end
end
