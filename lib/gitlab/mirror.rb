module Gitlab
  module Mirror
    include Gitlab::CurrentSettings

    FIFTEEN = 15
    HOURLY  = 60
    THREE   = 180
    SIX     = 360
    TWELVE  = 720
    DAILY   = 1440

    INTERVAL_BEFORE_FIFTEEN = 14.minutes

    SYNC_TIME_TO_CRON = {
      FIFTEEN => "*/15 * * * *",
      HOURLY  => "0 * * * *",
      THREE   => "0 */3 * * *",
      SIX     => "0 */6 * * *",
      TWELVE  => "0 */12 * * *",
      DAILY   => "0 0 * * *",
    }.freeze

    SYNC_TIME_OPTIONS = {
      "Update every 15 minutes"   => FIFTEEN,
      "Update hourly"             => HOURLY,
      "Update every three hours"  => THREE,
      "Update every six hours"    => SIX,
      "Update every twelve hours" => TWELVE,
      "Update every day"          => DAILY,
    }.freeze

    class << self
      def sync_times
        sync_times = [FIFTEEN]
        sync_times << DAILY  if at_beginning_of_day?
        sync_times << TWELVE if at_beginning_of_hour?(12)
        sync_times << SIX    if at_beginning_of_hour?(6)
        sync_times << THREE  if at_beginning_of_hour?(3)
        sync_times << HOURLY if at_beginning_of_hour?

        sync_times
      end

      def update_all_mirrors_cron_job
        Sidekiq::Cron::Job.find("update_all_mirrors_worker")
      end

      def destroy_cron_job!
        update_all_mirrors_cron_job&.destroy
      end

      def configure_cron_job!
        if Gitlab::Geo.secondary?
          destroy_cron_job!
          return
        end

        minimum_mirror_sync_time = current_application_settings.minimum_mirror_sync_time rescue FIFTEEN
        sync_time = SYNC_TIME_TO_CRON[minimum_mirror_sync_time]
        destroy_cron_job!

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

      def at_beginning_of_hour?(hour_mark = nil)
        start_at = DateTime.now.at_beginning_of_hour
        end_at = start_at + INTERVAL_BEFORE_FIFTEEN

        between_interval = DateTime.now.between?(start_at, end_at)
        return between_interval unless hour_mark

        between_interval && DateTime.now.hour % hour_mark == 0
      end
    end
  end
end
