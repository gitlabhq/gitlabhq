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
      def configure
        Sentry.init do |config|
          config.dsn = sentry_dsn
          config.release = Gitlab.revision
          config.environment = sentry_environment
          config.before_send = method(:before_send)
          config.background_worker_threads = 0
          config.send_default_pii = true
          config.send_modules = false
          config.traces_sample_rate = 0.2 if Gitlab::Utils.to_boolean(ENV['ENABLE_SENTRY_PERFORMANCE_MONITORING'])
          # Reason for disabling the below configs https://gitlab.com/gitlab-org/gitlab/-/merge_requests/150771#note_1881953691
          config.metrics.enabled = false
          config.metrics.enable_code_locations = false
          config.propagate_traces = false
          config.trace_propagation_targets = []
          config.enabled_patches = [:sidekiq_cron]
          config.enable_tracing = false

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

      # This should be used when you want to track the exception and not raise
      # with the default trackers (Sentry and Logger).
      #
      # If the exception implements the method `sentry_extra_data` and that method
      # returns a Hash, then the return value of that method will be merged into
      # `extra`. Exceptions can use this mechanism to provide structured data
      # to sentry in addition to their message and back-trace.
      def track_exception(exception, extra = {}, tags = {})
        process_exception(exception, extra: extra, tags: tags)
      end

      # This should be used when you only want to log the exception,
      # but not send it to Sentry or raise.
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
          # There is a possibility that this method is called before Sentry is
          # configured. Since Sentry 4.0, some methods of Sentry are forwarded to
          # to `nil`, hence we have to check the client as well.
          destinations << ::Sentry if ::Sentry.get_current_client && ::Sentry.configuration.dsn
          destinations << Logger
        end
      end

      # Some configuration attributes like `dsn`, and `environment`
      # can be configured both via `ENV` and `Application Settings`.
      # The reason being is while GitLab.com uses application_settings
      # in Geo installations, we can't override values in the primary database.
      # Setting this value in application_settings would propagate the value
      # to all Geo nodes, which doesn't solve that particular problem.
      def sentry_dsn
        env_sentry_dsn || database_sentry_dsn
      end

      def sentry_environment
        env_sentry_environment || database_sentry_environment
      end

      def database_sentry_dsn
        return unless sentry_configurable?
        return unless database_sentry_enabled?

        Gitlab::CurrentSettings.sentry_dsn
      end

      def env_sentry_dsn
        return unless sentry_configurable?
        return unless env_sentry_enabled?

        Gitlab.config.sentry.dsn
      end

      def env_sentry_environment
        return unless sentry_configurable?
        return unless env_sentry_enabled?

        Gitlab.config.sentry.environment
      end

      def database_sentry_environment
        return unless sentry_configurable?
        return unless database_sentry_enabled?
        return unless Gitlab::CurrentSettings.respond_to?(:sentry_environment)

        Gitlab::CurrentSettings.sentry_environment
      end

      def database_sentry_enabled?
        Gitlab::CurrentSettings.respond_to?(:sentry_enabled?) &&
          Gitlab::CurrentSettings.sentry_enabled?
      end

      def env_sentry_enabled?
        Gitlab.config.sentry.enabled
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
