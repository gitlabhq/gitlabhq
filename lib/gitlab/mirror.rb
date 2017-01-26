module Gitlab
  module Mirror

    FIFTEEN = 15
    HOURLY  = 60
    DAYLY   = 1440

    class << self
      def sync_time_options
        {
          "Update every 15 minutes" => FIFTEEN,
          "Update hourly" => HOURLY,
          "Update every day" => DAYLY,
        }
      end

      def sync_times
        sync_times = [FIFTEEN]
        sync_times << DAYLY  if at_beginning_of_day?
        sync_times << HOURLY if at_beginning_of_hour?

        return sync_times
      end

      def at_beginning_of_day?
        beginning_of_day = DateTime.now.at_beginning_of_day
        DateTime.now >= beginning_of_day && DateTime.now <= beginning_of_day + 14.minutes
      end

      def at_beginning_of_hour?
        beginning_of_hour = DateTime.now.at_beginning_of_hour
        DateTime.now >= beginning_of_hour && DateTime.now <= beginning_of_hour + 14.minutes
      end
    end
  end
end
