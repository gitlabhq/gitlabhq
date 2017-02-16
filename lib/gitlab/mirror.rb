module Gitlab
  module Mirror
    include Gitlab::CurrentSettings

    FIFTEEN = 15
    HOURLY  = 60
    DAILY = 1440

    INTERVAL_BEFORE_FIFTEEN = 14.minutes

    SYNC_TIME_TO_CRON = {
      FIFTEEN => "*/15 * * * *",
      HOURLY  => "0 * * * *",
      DAILY   => "0 0 * * *"
    }.freeze

    SYNC_TIME_OPTIONS = {
      "Update every 15 minutes" => FIFTEEN,
      "Update hourly" => HOURLY,
      "Update every day" => DAILY,
    }.freeze

    class << self
      def sync_times
        sync_times = [FIFTEEN]
        sync_times << DAILY  if at_beginning_of_day?
        sync_times << HOURLY if at_beginning_of_hour?

        sync_times
      end

      def configure_cron_jobs!
        minimum_mirror_sync_time = current_application_settings.minimum_mirror_sync_time rescue FIFTEEN
        sync_time = SYNC_TIME_TO_CRON[minimum_mirror_sync_time]
        update_all_mirrors_worker_job = Sidekiq::Cron::Job.find("update_all_mirrors_worker")
        update_all_remote_mirrors_worker_job = Sidekiq::Cron::Job.find("update_all_remote_mirrors_worker")

        if update_all_mirrors_worker_job && update_all_remote_mirrors_worker_job
          update_all_mirrors_worker_job.destroy
          update_all_remote_mirrors_worker_job.destroy
        end

        Sidekiq::Cron::Job.create(
          name: 'update_all_remote_mirrors_worker',
          cron: sync_time,
          class: 'UpdateAllRemoteMirrorsWorker'
        )
        Sidekiq::Cron::Job.create(
          name: 'update_all_mirrors_worker',
          cron: sync_time,
          class: 'UpdateAllMirrorsWorker'
        )
      end

      def at_beginning_of_day?
        start_at = DateTime.now.at_beginning_of_day
        end_at = start_at + INTERVAL_BEFORE_FIFTEEN

        DateTime.now.between?(start_at, end_at)
      end

      def at_beginning_of_hour?
        start_at = DateTime.now.at_beginning_of_hour
        end_at = start_at + INTERVAL_BEFORE_FIFTEEN

        DateTime.now.between?(start_at, end_at)
      end
    end
  end
end
