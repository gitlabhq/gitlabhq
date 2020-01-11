# frozen_string_literal: true

require 'active_record'
require 'active_record/log_subscriber'

module Gitlab
  module SidekiqLogging
    class StructuredLogger
      MAXIMUM_JOB_ARGUMENTS_LENGTH = 10.kilobytes

      def call(job, queue)
        started_time = get_time
        base_payload = parse_job(job)
        ActiveRecord::LogSubscriber.reset_runtime

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

        scheduling_latency_s = ::Gitlab::InstrumentationHelper.queue_duration_for_job(payload)
        payload['scheduling_latency_s'] = scheduling_latency_s if scheduling_latency_s

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
          payload['error_class'] = job_exception.class.name
        else
          payload['message'] = "#{message}: done: #{payload['duration']} sec"
          payload['job_status'] = 'done'
        end

        payload['db_duration'] = ActiveRecord::LogSubscriber.runtime
        payload['db_duration_s'] = payload['db_duration'] / 1000

        payload
      end

      def add_time_keys!(time, payload)
        payload['duration'] = time[:duration].round(6)

        # ignore `cpu_s` if the platform does not support Process::CLOCK_THREAD_CPUTIME_ID (time[:cputime] == 0)
        # supported OS version can be found at: https://www.rubydoc.info/stdlib/core/2.1.6/Process:clock_gettime
        payload['cpu_s'] = time[:cputime].round(6) if time[:cputime] > 0
        payload['completed_at'] = Time.now.utc.to_f
      end

      def parse_job(job)
        job = job.dup

        # Add process id params
        job['pid'] = ::Process.pid

        job.delete('args') unless ENV['SIDEKIQ_LOG_ARGUMENTS']
        job['args'] = limited_job_args(job['args']) if job['args']

        job
      end

      def elapsed(t0)
        t1 = get_time
        {
          duration: t1[:now] - t0[:now],
          cputime: t1[:thread_cputime] - t0[:thread_cputime]
        }
      end

      def get_time
        {
          now: current_time,
          thread_cputime: defined?(Process::CLOCK_THREAD_CPUTIME_ID) ? Process.clock_gettime(Process::CLOCK_THREAD_CPUTIME_ID) : 0
        }
      end

      def current_time
        Gitlab::Metrics::System.monotonic_time
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
