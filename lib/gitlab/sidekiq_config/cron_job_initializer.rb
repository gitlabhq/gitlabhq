# frozen_string_literal: true

module Gitlab
  module SidekiqConfig
    class CronJobInitializer
      class << self
        # We apply Sidekiq job configurations for example during Rails initialization. Jobs have a `status` attribute
        # with one of following values:
        # - `nil`: Job is enabled.
        # - `enabled`: Job is enabled.
        # - `disabled`: Job is disabled.
        # Reapplying configurations with `nil` status won't update a status of `enabled` or `disabled`.
        # After applying the defaults, jobs are disabled or setup up based on the node type (e.g., non-geo,
        # primary geo, or secondary geo).

        def execute
          # Set source to schedule to clear any missing jobs
          # See https://github.com/sidekiq-cron/sidekiq-cron/pull/431
          Sidekiq::Cron::Job.load_from_hash! Gitlab::SidekiqConfig.cron_jobs, source: 'schedule'

          Gitlab.ee do
            Gitlab::Mirror.configure_cron_job!

            Gitlab::Geo.configure_cron_jobs!
          end
        end
      end
    end
  end
end
