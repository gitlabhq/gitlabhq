module Gitlab
  module Sentry
    def self.enabled?
      Rails.env.production? && Gitlab::CurrentSettings.sentry_enabled?
    end

    def self.context(current_user = nil)
      return unless self.enabled?

      Raven.tags_context(locale: I18n.locale)

      if current_user
        Raven.user_context(
          id: current_user.id,
          email: current_user.email,
          username: current_user.username
        )
      end
    end

    def self.program_context
      if Sidekiq.server?
        'sidekiq'
      else
        'rails'
      end
    end
  end
end
