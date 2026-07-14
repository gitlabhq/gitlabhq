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
          load_dynamic_cron_schedules!

          # Disable on JH before loading into the registry so the registry reflects the correct status.
          Gitlab.jh do
            if Gitlab::SidekiqConfig.cron_jobs['gitlab_subscriptions_offline_cloud_license_provision_worker']
              Gitlab::SidekiqConfig::CronJobs.config.set_job(
                'gitlab_subscriptions_offline_cloud_license_provision_worker',
                { 'status' => 'disabled' }
              )
            end
          end

          # Set source to schedule to clear any missing jobs
          # See https://github.com/sidekiq-cron/sidekiq-cron/pull/431
          Sidekiq::Cron::Job.load_from_hash! Gitlab::SidekiqConfig.cron_jobs.transform_values(&:dup), source: 'schedule'

          Gitlab.ee do
            Gitlab::Mirror.configure_cron_job!

            Gitlab::Geo.configure_cron_jobs!
          end
        end

        private

        # Migrated from Settings#load_dynamic_cron_schedules! in config/settings.rb.
        def load_dynamic_cron_schedules!
          Gitlab::SidekiqConfig::CronJobs.config.set_job(
            'gitlab_service_ping_worker',
            { 'cron' => cron_for_service_ping }
          )

          Gitlab::SidekiqConfig::CronJobs.config.set_job(
            'sync_seat_link_worker',
            { 'cron' => "#{rand(60)} #{rand(3..4)} * * * UTC" }
          )

          Gitlab::SidekiqConfig::CronJobs.config.set_job(
            'sync_service_token_worker',
            { 'cron' => "#{rand(60)} * * * * UTC" }
          )
        end

        # Computes a per-instance random schedule from the instance UUID so that
        # service pings are distributed across instances rather than firing all at once.
        #
        # @return [String]
        def cron_for_service_ping
          uuid   = Gitlab::CurrentSettings.uuid || GITLAB_INSTANCE_UUID_NOT_SET
          minute = Digest::SHA256.hexdigest("#{uuid}minute").to_i(16) % 60
          hour   = Digest::SHA256.hexdigest("#{uuid}hour").to_i(16) % 24
          dow    = Digest::SHA256.hexdigest(uuid).to_i(16) % 7

          "#{minute} #{hour} * * #{dow}"
        end
      end
    end
  end
end
