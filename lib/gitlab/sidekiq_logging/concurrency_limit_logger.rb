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
    end
  end
end
