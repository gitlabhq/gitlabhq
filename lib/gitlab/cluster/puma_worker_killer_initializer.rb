# frozen_string_literal: true

module Gitlab
  module Cluster
    class PumaWorkerKillerInitializer
      def self.start(
        puma_options,
          puma_per_worker_max_memory_mb: 850,
          puma_master_max_memory_mb: 550,
          additional_puma_dev_max_memory_mb: 200
      )
        require 'puma_worker_killer'

        PumaWorkerKiller.config do |config|
          # Note! ram is expressed in megabytes (whereas GITLAB_UNICORN_MEMORY_MAX is in bytes)
          # Importantly RAM is for _all_workers (ie, the cluster),
          # not each worker as is the case with GITLAB_UNICORN_MEMORY_MAX
          worker_count = puma_options[:workers] || 1
          # The Puma Worker Killer checks the total RAM used by both the master
          # and worker processes.
          # https://github.com/schneems/puma_worker_killer/blob/v0.1.0/lib/puma_worker_killer/puma_memory.rb#L57
          #
          # Additional memory is added when running in `development`
          config.ram = puma_master_max_memory_mb +
            (worker_count * puma_per_worker_max_memory_mb) +
            (Rails.env.development? ? (1 + worker_count) * additional_puma_dev_max_memory_mb : 0)

          config.frequency = 20 # seconds

          # We just want to limit to a fixed maximum, unrelated to the total amount
          # of available RAM.
          config.percent_usage = 0.98

          # Ideally we'll never hit the maximum amount of memory. Restart the workers
          # regularly rather than rely on OOM behavior for periodic restarting.
          config.rolling_restart_frequency = 43200 # 12 hours in seconds.

          observer = Gitlab::Cluster::PumaWorkerKillerObserver.new
          config.pre_term = observer.callback
        end

        PumaWorkerKiller.start
      end
    end
  end
end
