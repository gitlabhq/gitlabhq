# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    class << self
      def configure
        Raven.configure do |config|
          config.dsn = sentry_dsn
          config.release = Gitlab.revision
          config.current_environment = Gitlab.config.sentry.environment

          # Sanitize fields based on those sanitized from Rails.
          config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)
          # Sanitize authentication headers
          config.sanitize_http_headers = %w[Authorization Private-Token]
          config.tags = { program: Gitlab.process_name }
          # Debugging for https://gitlab.com/gitlab-org/gitlab-foss/issues/57727
          config.before_send = method(:add_context_from_exception_type)
        end
      end

      def with_context(current_user = nil)
        last_user_context = Raven.context.user

        user_context = {
          id: current_user&.id,
          email: current_user&.email,
          username: current_user&.username
        }.compact

        Raven.tags_context(default_tags)
        Raven.user_context(user_context)

        yield
      ensure
        Raven.user_context(last_user_context)
      end

      # This should be used when you want to passthrough exception handling:
      # rescue and raise to be catched in upper layers of the application.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def track_and_raise_exception(exception, extra = {})
        process_exception(exception, sentry: true, extra: extra)

        raise exception
      end

      # This can be used for investigating exceptions that can be recovered from in
      # code. The exception will still be raised in development and test
      # environments.
      #
      # That way we can track down these exceptions with as much information as we
      # need to resolve them.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      #
      # Provide an issue URL for follow up.
      # as `issue_url: 'http://gitlab.com/gitlab-org/gitlab/issues/111'`
      def track_and_raise_for_dev_exception(exception, extra = {})
        process_exception(exception, sentry: true, extra: extra)

        raise exception if should_raise_for_dev?
      end

      # This should be used when you only want to track the exception.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def track_exception(exception, extra = {})
        process_exception(exception, sentry: true, extra: extra)
      end

      # This should be used when you only want to log the exception,
      # but not send it to Sentry.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def log_exception(exception, extra = {})
        process_exception(exception, extra: extra)
      end

      private

      def process_exception(exception, sentry: false, logging: true, extra:)
        exception.try(:sentry_extra_data)&.tap do |data|
          extra = extra.merge(data) if data.is_a?(Hash)
        end

        if sentry && Raven.configuration.server
          Raven.capture_exception(exception, tags: default_tags, extra: extra)
        end

        if logging
          # TODO: this logic could migrate into `Gitlab::ExceptionLogFormatter`
          # and we could also flatten deep nested hashes if required for search
          # (e.g. if `extra` includes hash of hashes).
          # In the current implementation, we don't flatten multi-level folded hashes.
          log_hash = {}
          Raven.context.tags.each { |name, value| log_hash["tags.#{name}"] = value }
          Raven.context.user.each { |name, value| log_hash["user.#{name}"] = value }
          Raven.context.extra.merge(extra).each { |name, value| log_hash["extra.#{name}"] = value }

          Gitlab::ExceptionLogFormatter.format!(exception, log_hash)

          Gitlab::ErrorTracking::Logger.error(log_hash)
        end
      end

      def sentry_dsn
        return unless Rails.env.production? || Rails.env.development?
        return unless Gitlab.config.sentry.enabled

        Gitlab.config.sentry.dsn
      end

      def should_raise_for_dev?
        Rails.env.development? || Rails.env.test?
      end

      def default_tags
        {
          Labkit::Correlation::CorrelationId::LOG_KEY.to_sym => Labkit::Correlation::CorrelationId.current_id,
          locale: I18n.locale
        }
      end

      def add_context_from_exception_type(event, hint)
        if ActiveModel::MissingAttributeError === hint[:exception]
          columns_hash = ActiveRecord::Base
                            .connection
                            .schema_cache
                            .instance_variable_get(:@columns_hash)
                            .map { |k, v| [k, v.map(&:first)] }
                            .to_h

          event.extra.merge!(columns_hash)
        end

        event
      end
    end
  end
end
