# frozen_string_literal: true

module Gitlab
  module Usage
    module TimeSeriesStorable
      # requires a #redis_key(event, date, used_in_aggregate_metric) method to be defined
      def keys_for_aggregation(events:, start_date:, end_date:, used_in_aggregate_metric: false)
        # we always keep 1 week of margin
        # .end_of_week is necessary to make sure this works for 1 week long periods too
        end_date = end_date.end_of_week - 1.week
        (start_date.to_date..end_date.to_date).flat_map do |date|
          events.map { |event| redis_key(event, date, used_in_aggregate_metric) }
        end.uniq
      end

      def apply_time_aggregation(key, time)
        year_week = time.strftime('%G-%V')
        "#{key}-#{year_week}"
      end
    end
  end
end
