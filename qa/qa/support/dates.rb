# frozen_string_literal: true

module QA
  module Support
    module Dates
      def current_date_yyyy_mm_dd
        current_date.strftime("%Y/%m/%d")
      end

      def next_month_yyyy_mm_dd
        current_date.next_month.strftime("%Y/%m/%d")
      end

      def current_date_yyyy_mm_dd_iso
        current_date.to_date.iso8601
      end

      def next_month_yyyy_mm_dd_iso
        current_date.next_month.to_date.iso8601
      end

      def thirteen_days_from_now_yyyy_mm_dd
        (current_date + 13).strftime("%Y/%m/%d")
      end

      def format_date(date)
        new_date = DateTime.strptime(date, "%Y/%m/%d")
        new_date.strftime("%b %-d, %Y")
      end

      def format_date_without_year(date)
        new_date = DateTime.strptime(date, "%Y/%m/%d")
        new_date.strftime("%b %-d")
      end

      def iteration_period(start_date, due_date, use_thin_space: true)
        start_date = DateTime.strptime(start_date, "%Y/%m/%d")
        due_date = DateTime.strptime(due_date, "%Y/%m/%d")
        separator = use_thin_space ? " – " : " – "

        if start_date.year == due_date.year
          if start_date.month == due_date.month
            # Same year and same month: show only the day for the start date
            # and full format for the due date.
            "#{start_date.strftime('%b %-d')}#{separator}#{due_date.strftime('%-d, %Y')}"
          else
            # Same year but different month: show full start date and month/day for the due date.
            "#{start_date.strftime('%b %-d')}#{separator}#{due_date.strftime('%b %-d, %Y')}"
          end
        else
          # Different year: show the full format for both dates.
          "#{start_date.strftime('%b %-d, %Y')}#{separator}#{due_date.strftime('%b %-d, %Y')}"
        end
      end

      private

      def current_date
        DateTime.now
      end
    end
  end
end
