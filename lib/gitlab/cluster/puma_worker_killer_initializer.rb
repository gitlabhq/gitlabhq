# frozen_string_literal: true

module Gitlab
  module Cluster
    class PumaWorkerKillerInitializer
      def self.start(puma_config)
        require 'puma_worker_killer'

        PumaWorkerKiller.config do |config|
          # For now we use the same environment variable as Unicorn, making it
          # easier to replace Unicorn with Puma.

          # Note! ram is expressed in megabytes, whereas GITLAB_UNICORN_MEMORY_MAX is in bytes
          # Importantly RAM is for _all_workers, not each worker as is the case with GITLAB_UNICORN_MEMORY_MAX
          worker_count = puma_config.options[:workers] || 1
          config.ram = worker_count * (ENV['GITLAB_UNICORN_MEMORY_MAX'] ? ENV['GITLAB_UNICORN_MEMORY_MAX'].to_i / (1 << 20) : 650)

          config.frequency = 20 # seconds

          # We just wan't to limit to a fixed maximum, unrelated to the total amount
          # of available RAM.
          config.percent_usage = 0.98

          # Ideally we'll never hit the maximum amount of memory. If so the worker
          # is restarted already, thus periodically restarting workers shouldn't be
          # needed.
          config.rolling_restart_frequency = false
        end

        PumaWorkerKiller.start
      end
    end
  end
end
