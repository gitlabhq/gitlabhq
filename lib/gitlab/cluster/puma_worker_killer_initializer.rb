# frozen_string_literal: true

module Gitlab
  module Cluster
    class PumaWorkerKillerInitializer
      def self.start(
        puma_options,
          puma_per_worker_max_memory_mb: 1024,
          puma_master_max_memory_mb: 800,
          additional_puma_dev_max_memory_mb: 200
      )
        require 'puma_worker_killer'

        PumaWorkerKiller.config do |config|
          worker_count = puma_options[:workers] || 1
          # The Puma Worker Killer checks the total memory used by the cluster,
          # i.e. both primary and worker processes.
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

          # Spread the rolling restarts out over 1 hour to avoid too many simultaneous
          # process startups.
          config.rolling_restart_splay_seconds = 0.0..3600.0 # 0 to 1 hour in seconds.

          observer = Gitlab::Cluster::PumaWorkerKillerObserver.new
          config.pre_term = observer.callback
        end

        PumaWorkerKiller.start
      end
    end
  end
end
