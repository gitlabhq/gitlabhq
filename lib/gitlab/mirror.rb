module Gitlab
  module Mirror
    FIFTEEN = 15
    HOURLY  = 60
    DAYLY   = 1440

    PRECRON = 14.minutes

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
        start_at = DateTime.now.at_beginning_of_day
        end_at = start_at + PRECRON

        include_with_range?(start_at, end_at)
      end

      def at_beginning_of_hour?
        start_at = DateTime.now.at_beginning_of_hour
        end_at = start_at + PRECRON

        include_with_range?(start_at, end_at)
      end

      def include_with_range?(start_at, end_at)
        window = start_at...end_at
        window.include?(DateTime.now)
      end
    end
  end
end
