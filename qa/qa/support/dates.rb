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

      private

      def current_date
        DateTime.now
      end
    end
  end
end
