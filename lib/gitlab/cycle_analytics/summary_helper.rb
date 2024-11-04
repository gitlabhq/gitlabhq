# frozen_string_literal: true

module Gitlab
  module CycleAnalytics
    module SummaryHelper
      def frequency(count, from, to)
        return Summary::Value::None.new if count == 0

        freq = (count / days(from, to)).round(2)

        Summary::Value::Numeric.new(freq)
      end

      def days(from, to)
        [(to.end_of_day - from.beginning_of_day).fdiv(1.day), 1].max
      end
    end
  end
end
