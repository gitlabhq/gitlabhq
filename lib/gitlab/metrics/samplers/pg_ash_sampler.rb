# frozen_string_literal: true

module Gitlab
  module Metrics
    module Samplers
      class PgAshSampler < BaseSampler
        # This is how often a process retries the sampling lease, not how often
        # a sample is taken. The sample interval is an application setting and
        # is applied by PgAsh::Sampler. A 1s value here would make every
        # Sidekiq process hit Redis every second.
        DEFAULT_SAMPLING_INTERVAL_SECONDS = 30

        def sample
          return unless Gitlab::CurrentSettings.pg_ash_sampling_enabled
          return if Gitlab::Database.read_only?
          return unless Gitlab::Database::PgAsh::Installer.new.installed?

          Gitlab::Database::PgAsh::Sampler.new.execute { running }
        end
      end
    end
  end
end
