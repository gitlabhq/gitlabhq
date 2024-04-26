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
        Gitlab::SidekiqSharding::Validator.allow_unrouted_sidekiq_calls do
          # DeadSet is shard-local. It is correct to directly use Sidekiq.redis rather than to
          # route to another shard's DeadSet.
          ::Sidekiq::DeadSet.new.kill(payload, notify_failure: false)
        end

        # ignore retries
        raise ::Sidekiq::JobRetry::Skip
      end
    end
  end
end
