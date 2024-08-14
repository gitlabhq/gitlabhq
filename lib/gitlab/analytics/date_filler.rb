# frozen_string_literal: true

module Gitlab
  module Analytics
    # This class generates a date => value hash without gaps in the data points.
    #
    # Simple usage:
    #
    # > # We have the following data for the last 5 day:
    # > input = { 3.days.ago.to_date => 10, Date.today => 5 }
    #
    # > # Format this data, so we can chart the complete date range:
    # > Gitlab::Analytics::DateFiller.new(input, from: 4.days.ago, to: Date.today, default_value: 0).fill
    # > {
    # >  Sun, 28 Aug 2022=>0,
    # >  Mon, 29 Aug 2022=>10,
    # >  Tue, 30 Aug 2022=>0,
    # >  Wed, 31 Aug 2022=>0,
    # >  Thu, 01 Sep 2022=>5
    # > }
    #
    # Parameters:
    #
    # **input**
    # A Hash containing data for the series or the chart. The key is a Date object
    # or an object which can be converted to Date.
    #
    # **from**
    # Start date of the range
    #
    # **to**
    # End date of the range
    #
    # **period**
    # Specifies the period in which the dates should be generated. Options:
    #
    # - :day, generate date-value pair for each day in the given period
    # - :week, generate date-value pair for each week (beginning of the week date)
    # - :month, generate date-value pair for each week (beginning of the month date)
    #
    # Note: the Date objects in the `input` should follow the same pattern (beginning of ...)
    #
    # **default_value**
    #
    # Which value use when the `input` Hash does not contain data for the given day.
    #
    # **date_formatter**
    #
    # How to format the dates in the resulting hash.
    class DateFiller
      DEFAULT_DATE_FORMATTER = ->(date) { date }
      PERIOD_STEPS = {
        day: 1.day,
        week: 1.week,
        month: 1.month
      }.freeze

      def initialize(
        input,
        from:,
        to:,
        period: :day,
        default_value: nil,
        date_formatter: DEFAULT_DATE_FORMATTER)
        @input = input.transform_keys(&:to_date)
        @from = from.to_date
        @to = to.to_date
        @period = period
        @default_value = default_value
        @date_formatter = date_formatter
      end

      def fill
        data = {}

        current_date = from
        loop do
          transformed_date = transform_date(current_date)
          break if transformed_date > to

          formatted_date = date_formatter.call(transformed_date)

          value = input.delete(transformed_date)
          data[formatted_date] = value.nil? ? default_value : value

          current_date = (current_date + PERIOD_STEPS.fetch(period)).to_date
        end

        data
      end

      private

      attr_reader :input, :from, :to, :period, :default_value, :date_formatter

      def transform_date(date)
        case period
        when :day
          date.beginning_of_day.to_date
        when :week
          date.beginning_of_week.to_date
        when :month
          date.beginning_of_month.to_date
        else
          raise "Unknown period given: #{period}"
        end
      end
    end
  end
end
