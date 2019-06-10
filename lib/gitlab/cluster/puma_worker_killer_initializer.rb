# frozen_string_literal: true

module Gitlab
  module Cluster
    class PumaWorkerKillerInitializer
      def self.start(puma_options, puma_per_worker_max_memory_mb: 650)
        require 'puma_worker_killer'

        PumaWorkerKiller.config do |config|
          # Note! ram is expressed in megabytes (whereas GITLAB_UNICORN_MEMORY_MAX is in bytes)
          # Importantly RAM is for _all_workers (ie, the cluster),
          # not each worker as is the case with GITLAB_UNICORN_MEMORY_MAX
          worker_count = puma_options[:workers] || 1
          # The Puma Worker Killer checks the total RAM used by both the master
          # and worker processes. Bump the limits to N+1 instead of N workers
          # to account for this:
          # https://github.com/schneems/puma_worker_killer/blob/v0.1.0/lib/puma_worker_killer/puma_memory.rb#L57
          config.ram = (worker_count + 1) * puma_per_worker_max_memory_mb

          config.frequency = 20 # seconds

          # We just want to limit to a fixed maximum, unrelated to the total amount
          # of available RAM.
          config.percent_usage = 0.98

          # Ideally we'll never hit the maximum amount of memory. If so the worker
          # is restarted already, thus periodically restarting workers shouldn't be
          # needed.
          config.rolling_restart_frequency = false

          observer = Gitlab::Cluster::PumaWorkerKillerObserver.new
          config.pre_term = observer.callback
        end

        PumaWorkerKiller.start
      end
    end
  end
end
