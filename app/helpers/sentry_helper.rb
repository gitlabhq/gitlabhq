# frozen_string_literal: true

module SentryHelper
  def sentry_enabled?
    Gitlab::Sentry.enabled?
  end

  def sentry_context
    Gitlab::Sentry.context(current_user)
  end
end
