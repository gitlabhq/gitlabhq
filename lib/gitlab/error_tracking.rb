# frozen_string_literal: true

module Gitlab
  module ErrorTracking
    # Exceptions in this group will receive custom Sentry fingerprinting
    CUSTOM_FINGERPRINTING = %w[
      Acme::Client::Error::BadNonce
      Acme::Client::Error::NotFound
      Acme::Client::Error::RateLimited
      Acme::Client::Error::Timeout
      Acme::Client::Error::UnsupportedOperation
      ActiveRecord::ConnectionTimeoutError
      Gitlab::RequestContext::RequestDeadlineExceeded
      GRPC::DeadlineExceeded
      JIRA::HTTPError
      Rack::Timeout::RequestTimeoutException
    ].freeze

    PROCESSORS = [
      ::Gitlab::ErrorTracking::Processor::SidekiqProcessor,
      ::Gitlab::ErrorTracking::Processor::GrpcErrorProcessor,
      ::Gitlab::ErrorTracking::Processor::ContextPayloadProcessor,
      ::Gitlab::ErrorTracking::Processor::SanitizeErrorMessageProcessor,
      # IMPORTANT: this processor must stay at the bottom, right before
      # sending the event to Sentry.
      ::Gitlab::ErrorTracking::Processor::SanitizerProcessor
    ].freeze

    class << self
      def configure(&block)
        configure_raven(&block)
        configure_sentry(&block)
      end

      def configure_raven
        Raven.configure do |config|
          config.dsn = sentry_dsn
          config.release = Gitlab.revision
          config.current_environment = Gitlab.config.sentry.environment

          # Sanitize fields based on those sanitized from Rails.
          config.sanitize_fields = Rails.application.config.filter_parameters.map(&:to_s)

          # Sanitize authentication headers
          config.sanitize_http_headers = %w[Authorization Private-Token]
          config.before_send = method(:before_send_raven)

          yield config if block_given?
        end
      end

      def configure_sentry
        Sentry.init do |config|
          config.dsn = new_sentry_dsn
          config.release = Gitlab.revision
          config.environment = new_sentry_environment
          config.before_send = method(:before_send_sentry)
          config.background_worker_threads = 0
          config.send_default_pii = true
          config.send_modules = false
          config.traces_sample_rate = 0.2 if Gitlab::Utils.to_boolean(ENV['ENABLE_SENTRY_PERFORMANCE_MONITORING'])

          yield config if block_given?
        end
      end

      # This should be used when you want to passthrough exception handling:
      # rescue and raise to be catched in upper layers of the application.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def track_and_raise_exception(exception, extra = {}, tags = {})
        process_exception(exception, extra: extra, tags: tags)

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
      def track_and_raise_for_dev_exception(exception, extra = {}, tags = {})
        process_exception(exception, extra: extra, tags: tags)

        raise exception if should_raise_for_dev?
      end

      # This should be used when you only want to track the exception.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def track_exception(exception, extra = {}, tags = {})
        process_exception(exception, extra: extra, tags: tags)
      end

      # This should be used when you only want to log the exception,
      # but not send it to Sentry.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def log_exception(exception, extra = {})
        process_exception(exception, extra: extra, trackers: [Logger])
      end

      # This should be used when you want to log the exception and passthrough
      # exception handling: rescue and raise to be catched in upper layers of
      # the application.
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def log_and_raise_exception(exception, extra = {})
        process_exception(exception, extra: extra, trackers: [Logger])

        raise exception
      end

      private

      def before_send_raven(event, hint)
        return unless Feature.enabled?(:enable_old_sentry_integration)

        before_send(event, hint)
      end

      def before_send_sentry(event, hint)
        return unless Feature.enabled?(:enable_new_sentry_integration)

        before_send(event, hint)
      end

      def before_send(event, hint)
        # Don't report Sidekiq retry errors to Sentry
        return if hint[:exception].is_a?(Gitlab::SidekiqMiddleware::RetryError)

        inject_context_for_exception(event, hint[:exception])
        custom_fingerprinting(event, hint[:exception])

        PROCESSORS.reduce(event) do |processed_event, processor|
          processor.call(processed_event)
        end
      end

      def process_exception(exception, extra:, tags: {}, trackers: default_trackers)
        Gitlab::Utils.allow_within_concurrent_ruby do
          context_payload = Gitlab::ErrorTracking::ContextPayloadGenerator.generate(exception, extra, tags)

          trackers.each do |tracker|
            tracker.capture_exception(exception, **context_payload)
          end
        end
      end

      def default_trackers
        [].tap do |destinations|
          destinations << Raven if Raven.configuration.server
          # There is a possibility that this method is called before Sentry is
          # configured. Since Sentry 4.0, some methods of Sentry are forwarded to
          # to `nil`, hence we have to check the client as well.
          destinations << ::Sentry if ::Sentry.get_current_client && ::Sentry.configuration.dsn
          destinations << Logger
        end
      end

      def sentry_dsn
        return unless sentry_configurable?
        return unless Gitlab.config.sentry.enabled

        Gitlab.config.sentry.dsn
      end

      def new_sentry_dsn
        return unless sentry_configurable?
        return unless Gitlab::CurrentSettings.respond_to?(:sentry_enabled?)
        return unless Gitlab::CurrentSettings.sentry_enabled?

        Gitlab::CurrentSettings.sentry_dsn
      end

      def new_sentry_environment
        return unless Gitlab::CurrentSettings.respond_to?(:sentry_environment)

        Gitlab::CurrentSettings.sentry_environment
      end

      def sentry_configurable?
        Rails.env.production? || Rails.env.development?
      end

      def should_raise_for_dev?
        Rails.env.development? || Rails.env.test?
      end

      # Group common, mostly non-actionable exceptions by type and message,
      # rather than cause
      def custom_fingerprinting(event, ex)
        return event unless CUSTOM_FINGERPRINTING.include?(ex.class.name)

        event.fingerprint = [ex.class.name, ex.message]
      end

      def inject_context_for_exception(event, ex)
        sql = Gitlab::ExceptionLogFormatter.find_sql(ex)

        event.extra[:sql] = sql if sql
      end
    end
  end
end
