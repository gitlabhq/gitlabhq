module Gitlab
  module Mirror

    QUARTER = 15
    HOUR = 60
    DAY = 1440

    class << self
      def mirror_options
        {
          "Update every 15 minutes": QUARTER,
          "Update hourly": HOUR,
          "Update every day": DAY,
        }
      end

      def to_cron(sync_time)
        case sync_time
        when QUARTER
          "*/15 * * * *"
        when HOUR
          "0 * * * *"
        when DAY
          "0 0 * * *"
        end
      end
    end
  end
end
