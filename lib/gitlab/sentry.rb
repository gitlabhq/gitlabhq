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

    # This can be used for investigating exceptions that can be recovered from in
    # code. The exception will still be raised in development and test
    # environments.
    #
    # That way we can track down these exceptions with as much information as we
    # need to resolve them.
    #
    # Provide an issue URL for follow up.
    def self.track_exception(exception, issue_url: nil, extra: {})
      if enabled?
        extra[:issue_url] = issue_url if issue_url
        context # Make sure we've set everything we know in the context

        Raven.capture_exception(exception, extra: extra)
      end

      raise exception if should_raise?
    end

    def self.program_context
      if Sidekiq.server?
        'sidekiq'
      else
        'rails'
      end
    end

    def self.should_raise?
      Rails.env.development? || Rails.env.test?
    end
  end
end
