# frozen_string_literal: true

require 'active_record'
require 'active_record/log_subscriber'

module Gitlab
  module SidekiqLogging
    class StructuredLogger
      include LogsJobs

      def call(job, queue)
        started_time = get_time
        base_payload = parse_job(job)

        ActiveRecord::LogSubscriber.reset_runtime

        Sidekiq.logger.info log_job_start(job, base_payload)

        yield

        Sidekiq.logger.info log_job_done(job, started_time, base_payload)
      rescue Sidekiq::JobRetry::Handled => job_exception
        # Sidekiq::JobRetry::Handled is raised by the internal Sidekiq
        # processor. It is a wrapper around real exception indicating an
        # exception is already handled by the Job retrier. The real exception
        # should be unwrapped before being logged.
        #
        # For more information:
        # https://github.com/mperham/sidekiq/blob/v5.2.7/lib/sidekiq/processor.rb#L173
        Sidekiq.logger.warn log_job_done(job, started_time, base_payload, job_exception.cause || job_exception)

        raise
      rescue StandardError => job_exception
        Sidekiq.logger.warn log_job_done(job, started_time, base_payload, job_exception)

        raise
      end

      private

      def add_instrumentation_keys!(job, output_payload)
        output_payload.merge!(job[:instrumentation].stringify_keys) if job[:instrumentation]
      end

      def add_logging_extras!(job, output_payload)
        output_payload.merge!(
          job.select { |key, _| key.to_s.start_with?("#{ApplicationWorker::LOGGING_EXTRA_KEY}.") }
        )
      end

      def log_job_start(job, payload)
        payload['message'] = "#{base_message(payload)}: start"
        payload['job_status'] = 'start'

        scheduling_latency_s = ::Gitlab::InstrumentationHelper.queue_duration_for_job(payload)
        payload['scheduling_latency_s'] = scheduling_latency_s if scheduling_latency_s

        payload
      end

      def log_job_done(job, started_time, payload, job_exception = nil)
        payload = payload.dup
        add_instrumentation_keys!(job, payload)
        add_logging_extras!(job, payload)

        elapsed_time = elapsed(started_time)
        add_time_keys!(elapsed_time, payload)

        message = base_message(payload)

        payload['load_balancing_strategy'] = job['load_balancing_strategy'] if job['load_balancing_strategy']

        if job_exception
          payload['message'] = "#{message}: fail: #{payload['duration_s']} sec"
          payload['job_status'] = 'fail'
          payload['error_message'] = job_exception.message
          payload['error_class'] = job_exception.class.name
          add_exception_backtrace!(job_exception, payload)
        else
          payload['message'] = "#{message}: done: #{payload['duration_s']} sec"
          payload['job_status'] = 'done'
        end

        db_duration = ActiveRecord::LogSubscriber.runtime
        payload['db_duration_s'] = Gitlab::Utils.ms_to_round_sec(db_duration)

        payload
      end

      def add_time_keys!(time, payload)
        payload['duration_s'] = time[:duration].round(Gitlab::InstrumentationHelper::DURATION_PRECISION)
        payload['completed_at'] = Time.now.utc.to_f
      end

      def add_exception_backtrace!(job_exception, payload)
        return if job_exception.backtrace.blank?

        payload['error_backtrace'] = Rails.backtrace_cleaner.clean(job_exception.backtrace)
      end

      def elapsed(t0)
        t1 = get_time
        { duration: t1[:now] - t0[:now] }
      end

      def get_time
        { now: current_time }
      end

      def current_time
        Gitlab::Metrics::System.monotonic_time
      end
    end
  end
end
