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
      # IMPORTANT: this processor must stay at the bottom, right before
      # sending the event to Sentry.
      ::Gitlab::ErrorTracking::Processor::SanitizerProcessor
    ].freeze

    class << self
      def configure
        Sentry.init do |config|
          config.dsn = sentry_dsn
          config.release = Gitlab.revision
          config.environment = Gitlab.config.sentry.environment
          config.before_send = method(:before_send)
          config.background_worker_threads = 0
          config.send_default_pii = true

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

      def before_send(event, hint)
        inject_context_for_exception(event, hint[:exception])
        custom_fingerprinting(event, hint[:exception])

        PROCESSORS.reduce(event) do |processed_event, processor|
          processor.call(processed_event)
        end
      end

      def process_exception(exception, sentry: false, logging: true, extra:)
        context_payload = Gitlab::ErrorTracking::ContextPayloadGenerator.generate(exception, extra)

        # There is a possibility that this method is called before Sentry is
        # configured. Since Sentry 4.0, some methods of Sentry are forwarded to
        # to `nil`, hence we have to check the client as well.
        if sentry && ::Sentry.get_current_client && ::Sentry.configuration.dsn
          ::Sentry.capture_exception(exception, **context_payload)
        end

        if logging
          formatter = Gitlab::ErrorTracking::LogFormatter.new
          log_hash = formatter.generate_log(exception, context_payload)

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

      # Group common, mostly non-actionable exceptions by type and message,
      # rather than cause
      def custom_fingerprinting(event, ex)
        return event unless CUSTOM_FINGERPRINTING.include?(ex.class.name)

        event.fingerprint = [ex.class.name, ex.message]
      end

      def inject_context_for_exception(event, ex)
        case ex
        when ActiveRecord::StatementInvalid
          event.extra[:sql] = PgQuery.normalize(ex.sql.to_s)
        else
          inject_context_for_exception(event, ex.cause) if ex.cause.present?
        end
      end
    end
  end
end
