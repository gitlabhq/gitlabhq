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
    #
    # If the exception implements the method `sentry_extra_data` and that method
    # returns a Hash, then the return value of that method will be merged into
    # `extra`. Exceptions can use this mechanism to provide structured data
    # to sentry in addition to their message and back-trace.
    def self.track_acceptable_exception(exception, issue_url: nil, extra: {})
      if enabled?
        extra = build_extra_data(exception, issue_url, extra)
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

    def self.build_extra_data(exception, issue_url, extra)
      exception.try(:sentry_extra_data)&.tap do |data|
        extra.merge!(data) if data.is_a?(Hash)
      end

      extra.merge({ issue_url: issue_url }.compact)
    end

    private_class_method :build_extra_data
  end
end
