# frozen_string_literal: true

module Gitlab
  module QuickActions
    # This class takes spend command argument
    # and separates date and time from spend command arguments if it present
    # example:
    # spend_command_time_and_date = "15m 2017-01-02"
    # SpendTimeAndDateSeparator.new(spend_command_time_and_date).execute
    # => [900, Mon, 02 Jan 2017]
    # if date doesn't present return time with current date
    # in other cases return nil
    class SpendTimeAndDateSeparator
      DATE_REGEX = %r{(\d{2,4}[/\-.]\d{1,2}[/\-.]\d{1,2})}
      CATEGORY_REGEX = %r{\[timecategory:(.*)\]}

      def initialize(spend_command_arg)
        @spend_arg = spend_command_arg
      end

      def execute
        return if @spend_arg.blank?
        return if date_present? && !valid_date?

        [time_spent, spent_at, category]
      end

      private

      def time_spent
        raw_time = @spend_arg.gsub(DATE_REGEX, '')
        raw_time = raw_time.gsub(CATEGORY_REGEX, '')

        Gitlab::TimeTrackingFormatter.parse(raw_time)
      end

      def spent_at
        return DateTime.current unless date_present?

        string_date = @spend_arg.match(DATE_REGEX)[0]
        Date.parse(string_date)
      end

      def date_present?
        DATE_REGEX =~ @spend_arg
      end

      def valid_date?
        string_date = @spend_arg.match(DATE_REGEX)[0]
        date = begin
          Date.parse(string_date)
        rescue StandardError
          nil
        end

        date_past_or_today?(date)
      end

      def date_past_or_today?(date)
        date&.past? || date&.today?
      end

      def category
        return unless @spend_arg.match?(CATEGORY_REGEX)

        @spend_arg.match(CATEGORY_REGEX)[1]
      end
    end
  end
end
