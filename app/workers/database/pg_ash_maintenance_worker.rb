# frozen_string_literal: true

module Database # rubocop:disable Gitlab/BoundedContexts -- home of the other database maintenance cron workers
  # One cron entry per pg_ash maintenance function; see config/schedule.yml.
  class PgAshMaintenanceWorker
    include ApplicationWorker
    include CronjobQueue # rubocop:disable Scalability/CronWorkerContext -- instance-wide job, no context to add

    feature_category :database
    data_consistency :sticky
    idempotent!
    loggable_arguments 0

    def perform(task)
      return unless Gitlab::CurrentSettings.pg_ash_sampling_enabled
      return if Gitlab::Database.read_only?
      return unless Gitlab::Database::PgAsh::Installer.new.installed?

      log_extra_metadata_on_done(:result, Gitlab::Database::PgAsh::Maintenance.new.run(task))
    end
  end
end
