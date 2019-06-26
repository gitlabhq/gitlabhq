# frozen_string_literal: true

module Gitlab
  module Sentry
    def self.enabled?
      (Rails.env.production? || Rails.env.development?) &&
        Gitlab.config.sentry.enabled
    end

    def self.context(current_user = nil)
      return unless enabled?

      Raven.tags_context(default_tags)

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
      track_acceptable_exception(exception, issue_url: issue_url, extra: extra)

      raise exception if should_raise_for_dev?
    end

    # This should be used when you do not want to raise an exception in
    # development and test. If you need development and test to behave
    # just the same as production you can use this instead of
    # track_exception.
    def self.track_acceptable_exception(exception, issue_url: nil, extra: {})
      if enabled?
        extra[:issue_url] = issue_url if issue_url
        context # Make sure we've set everything we know in the context

        Raven.capture_exception(exception, tags: default_tags, extra: extra)
      end
    end

    def self.should_raise_for_dev?
      Rails.env.development? || Rails.env.test?
    end

    def self.default_tags
      {
        Labkit::Correlation::CorrelationId::LOG_KEY.to_sym => Labkit::Correlation::CorrelationId.current_id,
        locale: I18n.locale
      }
    end
  end
end
