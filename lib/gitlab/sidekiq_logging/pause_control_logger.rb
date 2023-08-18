# frozen_string_literal: true

module Gitlab
  module SidekiqLogging
    class PauseControlLogger
      include Singleton
      include LogsJobs

      def paused_log(job, strategy:)
        payload = parse_job(job)
        payload['job_status'] = 'paused'
        payload['message'] = "#{base_message(payload)}: paused: #{strategy}"
        payload['pause_control.strategy'] = strategy

        Sidekiq.logger.info payload
      end

      def resumed_log(worker_name, args)
        job = {
          'class' => worker_name,
          'args' => args
        }
        payload = parse_job(job)
        payload['job_status'] = 'resumed'
        payload['message'] = "#{base_message(payload)}: resumed"

        Sidekiq.logger.info payload
      end
    end
  end
end
