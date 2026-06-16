# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class ConcurrencyLimitLogger
      include Singleton
      include LogsJobs

      def deferred_log(job)
        payload = parse_job(job)
        payload['job_status'] = 'concurrency_limit'
        payload['message'] = "#{base_message(payload)}: concurrency_limit: paused"

        Sidekiq.logger.info payload
      end

      def resumed_log(worker_name, args)
        job = {
          'class' => worker_name,
          'args' => args
        }
        payload = parse_job(job)
        payload['job_status'] = 'resumed'
        payload['message'] = "#{base_message(payload)}: concurrency_limit: resumed"

        Sidekiq.logger.info payload
      end

      def batch_resumed_log(worker_name, job_count)
        payload = parse_job({
          'class' => worker_name
        })
        payload['job_status'] = 'resumed'
        payload['resumed_job_count'] = job_count
        payload['message'] = "#{base_message(payload)}: concurrency_limit: resumed #{job_count} jobs"

        Sidekiq.logger.info payload
      end

      def worker_stats_log(worker_name, limit, queue_size, current)
        payload = parse_job({
          'class' => worker_name
        })
        payload['concurrency_limit'] = limit
        payload['concurrency_limit_queue_size'] = queue_size
        payload['current_concurrency'] = current

        Sidekiq.logger.info payload
      end

      def dropped_poison_job_log(worker_name, serialized_job, error)
        job = parse_serialized_job(serialized_job)
        context = job.delete('context') || {}
        payload = parse_job(job.merge('class' => worker_name))
        payload['job_status'] = 'dropped'
        payload['queue'] = worker_name.safe_constantize&.queue
        payload['message'] = "#{base_message(payload)}: concurrency_limit: dropped poison job from buffered queue"
        payload['exception.class'] = error.class.name
        payload['exception.message'] = error.message
        payload['job_size_bytes'] = serialized_job.bytesize
        payload['concurrency_limit_buffered_at'] = job['buffered_at']

        Sidekiq.logger.warn payload.merge(context)
      end

      private

      def parse_serialized_job(serialized_job)
        Gitlab::Json.safe_parse(serialized_job) || {}
      rescue StandardError
        {}
      end
    end
  end
end
