# frozen_string_literal: true

module Gitlab
  module SidekiqMiddleware
    class Monitor
      def call(worker, job, queue)
        Gitlab::SidekiqMonitor.instance.within_job(job['jid'], queue) do
          yield
        end
      end
    end
  end
end
