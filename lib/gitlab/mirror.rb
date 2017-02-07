module Gitlab
  module Mirror
    FIFTEEN = 15
    HOURLY  = 60
    DAILY = 1440

    INTERVAL_BEFORE_FIFTEEN = 14.minutes

    class << self
      def sync_time_options
        {
          "Update every 15 minutes" => FIFTEEN,
          "Update hourly" => HOURLY,
          "Update every day" => DAILY,
        }
      end

      def sync_times
        sync_times = [FIFTEEN]
        sync_times << DAILY  if at_beginning_of_day?
        sync_times << HOURLY if at_beginning_of_hour?

        sync_times
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
