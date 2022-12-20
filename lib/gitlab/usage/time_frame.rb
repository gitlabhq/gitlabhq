# frozen_string_literal: true

module Gitlab
  module Usage
    module TimeFrame
      ALL_TIME_TIME_FRAME_NAME = "all"
      SEVEN_DAYS_TIME_FRAME_NAME = "7d"
      TWENTY_EIGHT_DAYS_TIME_FRAME_NAME = "28d"
      DEFAULT_TIMESTAMP_COLUMN = :created_at

      def weekly_time_range
        { start_date: 7.days.ago.to_date, end_date: Date.current }
      end

      def monthly_time_range
        { start_date: 4.weeks.ago.to_date, end_date: Date.current }
      end

      # This time range is skewed for batch counter performance.
      # See https://gitlab.com/gitlab-org/gitlab/-/merge_requests/42972
      def monthly_time_range_db_params(column: nil)
        { (column || DEFAULT_TIMESTAMP_COLUMN) => 30.days.ago..2.days.ago }
      end

      def weekly_time_range_db_params(column: nil)
        { (column || DEFAULT_TIMESTAMP_COLUMN) => 9.days.ago..2.days.ago }
      end
    end
  end
end
