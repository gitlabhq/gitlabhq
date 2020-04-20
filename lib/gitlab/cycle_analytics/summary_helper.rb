# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module SummaryHelper
      def frequency(count, from, to)
        return count if count.zero?

        freq = (count / days(from, to)).round(1)
        freq.zero? ? '0' : freq
      end

      def days(from, to)
        [(to.end_of_day - from.beginning_of_day).fdiv(1.day), 1].max
      end
    end
  end
end
