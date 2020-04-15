# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module SummaryHelper
      def frequency(count, from, to)
        (count / days(from, to)).round(1)
      end

      def days(from, to)
        [(to.end_of_day - from.beginning_of_day) / (24 * 60 * 60), 1].max
      end
    end
  end
end
