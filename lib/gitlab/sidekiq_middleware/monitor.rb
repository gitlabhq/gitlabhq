# frozen_string_literal: true

require 'sidekiq/job_retry'

module Gitlab
  module SidekiqMiddleware
    class Monitor
      def call(worker, job, queue)
        Gitlab::SidekiqDaemon::Monitor.instance.within_job(worker.class, job['jid'], queue) do
          yield
        end
      rescue Gitlab::SidekiqDaemon::Monitor::CancelledError
        # push job to DeadSet
        payload = ::Sidekiq.dump_json(job)
        ::Sidekiq::DeadSet.new.kill(payload, notify_failure: false)

        # ignore retries
        raise ::Sidekiq::JobRetry::Skip
      end
    end
  end
end
