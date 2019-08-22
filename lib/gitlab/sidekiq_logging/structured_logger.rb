# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class StructuredLogger
      START_TIMESTAMP_FIELDS = %w[created_at enqueued_at].freeze
      DONE_TIMESTAMP_FIELDS = %w[started_at retried_at failed_at completed_at].freeze
      MAXIMUM_JOB_ARGUMENTS_LENGTH = 10.kilobytes

      def call(job, queue)
        started_time = get_time
        base_payload = parse_job(job)

        Sidekiq.logger.info log_job_start(base_payload)

        yield

        Sidekiq.logger.info log_job_done(job, started_time, base_payload)
      rescue => job_exception
        Sidekiq.logger.warn log_job_done(job, started_time, base_payload, job_exception)

        raise
      end

      private

      def base_message(payload)
        "#{payload['class']} JID-#{payload['jid']}"
      end

      def add_instrumentation_keys!(job, output_payload)
        output_payload.merge!(job.slice(*::Gitlab::InstrumentationHelper::KEYS))
      end

      def log_job_start(payload)
        payload['message'] = "#{base_message(payload)}: start"
        payload['job_status'] = 'start'

        # Old gitlab-shell messages don't provide enqueued_at/created_at attributes
        enqueued_at = payload['enqueued_at'] || payload['created_at']
        if enqueued_at
          payload['scheduling_latency_s'] = elapsed_by_absolute_time(Time.iso8601(enqueued_at))
        end

        payload
      end

      def log_job_done(job, started_time, payload, job_exception = nil)
        payload = payload.dup
        add_instrumentation_keys!(job, payload)

        elapsed_time = elapsed(started_time)
        add_time_keys!(elapsed_time, payload)

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

      def add_time_keys!(time, payload)
        payload['duration'] = time[:duration].round(3)
        payload['system_s'] = time[:stime].round(3)
        payload['user_s'] = time[:utime].round(3)
        payload['child_s'] = time[:ctime].round(3) if time[:ctime] > 0
        payload['completed_at'] = Time.now.utc
      end

      def parse_job(job)
        job = job.dup

        # Add process id params
        job['pid'] = ::Process.pid

        job.delete('args') unless ENV['SIDEKIQ_LOG_ARGUMENTS']
        job['args'] = limited_job_args(job['args']) if job['args']

        convert_to_iso8601(job, START_TIMESTAMP_FIELDS)

        job
      end

      def convert_to_iso8601(payload, keys)
        keys.each do |key|
          payload[key] = format_time(payload[key]) if payload[key]
        end
      end

      def elapsed_by_absolute_time(start)
        (Time.now.utc - start).to_f.round(3)
      end

      def elapsed(t0)
        t1 = get_time
        {
          duration: t1[:now] - t0[:now],
          stime: t1[:times][:stime] - t0[:times][:stime],
          utime: t1[:times][:utime] - t0[:times][:utime],
          ctime: ctime(t1[:times]) - ctime(t0[:times])
        }
      end

      def get_time
        {
          now: current_time,
          times: Process.times
        }
      end

      def ctime(times)
        times[:cstime] + times[:cutime]
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

      def limited_job_args(args)
        return unless args.is_a?(Array)

        total_length = 0
        limited_args = args.take_while do |arg|
          total_length += arg.to_json.length

          total_length <= MAXIMUM_JOB_ARGUMENTS_LENGTH
        end

        limited_args.push('...') if total_length > MAXIMUM_JOB_ARGUMENTS_LENGTH

        limited_args
      end
    end
  end
end
