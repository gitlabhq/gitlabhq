module SentryHelper
  def sentry_enabled?
    Rails.env.production? && current_application_settings.sentry_enabled?
  end

  def sentry_context
    return unless sentry_enabled?

    if current_user
      Raven.user_context(
        id: current_user.id,
        email: current_user.email,
        username: current_user.username,
      )
    end

    Raven.tags_context(program: sentry_program_context)
  end

  def sentry_program_context
    if Sidekiq.server?
      'sidekiq'
    else
      'rails'
    end
  end
end
