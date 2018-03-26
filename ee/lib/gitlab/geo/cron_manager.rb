module Gitlab
  module Geo
    class CronManager
      COMMON_JOBS = %w[geo_metrics_update_worker].freeze

      PRIMARY_JOBS = %w[
        geo_prune_event_log_worker
        geo_repository_verification_primary_batch_worker
      ].freeze

      SECONDARY_JOBS = %w[
        geo_repository_sync_worker
        geo_file_download_dispatch_worker
        geo_repository_verification_secondary_scheduler_worker
        geo_migrated_local_files_clean_up_worker
      ].freeze

      GEO_JOBS = (COMMON_JOBS + PRIMARY_JOBS + SECONDARY_JOBS).freeze

      CONFIG_WATCHER = 'geo_sidekiq_cron_config_worker'.freeze
      CONFIG_WATCHER_CLASS = 'Geo::SidekiqCronConfigWorker'.freeze

      def execute
        if Geo.connected? && Geo.primary?
          configure_primary
        elsif Geo.connected? && Geo.secondary?
          configure_secondary
        else
          enable!(all_jobs(except: GEO_JOBS))
          disable!(jobs(GEO_JOBS))
        end
      end

      def create_watcher!
        job(CONFIG_WATCHER)&.destroy

        Sidekiq::Cron::Job.create(
          name: CONFIG_WATCHER,
          cron: '*/1 * * * *',
          class: CONFIG_WATCHER_CLASS
        )
      end

      private

      def configure_primary
        disable!(jobs(SECONDARY_JOBS))
        enable!(all_jobs(except: SECONDARY_JOBS))
      end

      def configure_secondary
        names = [CONFIG_WATCHER, COMMON_JOBS, SECONDARY_JOBS].flatten

        disable!(all_jobs(except: names))
        enable!(jobs(names))
      end

      def enable!(jobs)
        jobs.compact.each { |job| job.enable! unless job.enabled? }
      end

      def disable!(jobs)
        jobs.compact.each { |job| job.disable! unless job.disabled? }
      end

      def all_jobs(except: [])
        Sidekiq::Cron::Job.all.reject { |job| except.include?(job.name) }
      end

      def jobs(names)
        names.map { |name| job(name) }
      end

      def job(name)
        Sidekiq::Cron::Job.find(name)
      end
    end
  end
end
