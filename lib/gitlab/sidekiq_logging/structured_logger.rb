module Gitlab
  module SidekiqLogging
    class StructuredLogger
      START_TIMESTAMP_FIELDS = %w[created_at enqueued_at].freeze
      DONE_TIMESTAMP_FIELDS = %w[started_at retried_at failed_at completed_at].freeze

      def call(job, queue)
        started_at = current_time
        base_payload = parse_job(job)

        Sidekiq.logger.info log_job_start(started_at, base_payload)

        yield

        Sidekiq.logger.info log_job_done(started_at, base_payload)
      rescue => job_exception
        Sidekiq.logger.warn log_job_done(started_at, base_payload, job_exception)

        raise
      end

      private

      def base_message(payload)
        "#{payload['class']} JID-#{payload['jid']}"
      end

      def log_job_start(started_at, payload)
        payload['message'] = "#{base_message(payload)}: start"
        payload['job_status'] = 'start'

        payload
      end

      def log_job_done(started_at, payload, job_exception = nil)
        payload = payload.dup
        payload['duration'] = elapsed(started_at)
        payload['completed_at'] = Time.now.utc

        message = base_message(payload)

        if job_exception
          payload['message'] = "#{message}: fail: #{payload['duration']} sec"
          payload['job_status'] = 'fail'
          payload['error_message'] = job_exception.message
          payload['error'] = job_exception.class
          payload['error_backtrace'] = backtrace_cleaner.clean(job_exception.backtrace)
        else
          payload['message'] = "#{message}: done: #{payload['duration']} sec"
          payload['job_status'] = 'done'
        end

        convert_to_iso8601(payload, DONE_TIMESTAMP_FIELDS)

        payload
      end

      def parse_job(job)
        job = job.dup

        # Add process id params
        job['pid'] = ::Process.pid

        job.delete('args') unless ENV['SIDEKIQ_LOG_ARGUMENTS']

        convert_to_iso8601(job, START_TIMESTAMP_FIELDS)

        job
      end

      def convert_to_iso8601(payload, keys)
        keys.each do |key|
          payload[key] = format_time(payload[key]) if payload[key]
        end
      end

      def elapsed(start)
        (current_time - start).round(3)
      end

      def current_time
        Gitlab::Metrics::System.monotonic_time
      end

      def backtrace_cleaner
        @backtrace_cleaner ||= ActiveSupport::BacktraceCleaner.new
      end

      def format_time(timestamp)
        return timestamp if timestamp.is_a?(String)

        Time.at(timestamp).utc.iso8601(3)
      end
    end
  end
end
