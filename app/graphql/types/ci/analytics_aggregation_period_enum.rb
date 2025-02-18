# frozen_string_literal: true

module Types
  module Ci
    class AnalyticsAggregationPeriodEnum < BaseEnum
      graphql_name 'AnalyticsAggregationPeriod'

      value 'DAY', description: 'Daily aggregation.', value: :day
      value 'WEEK', description: 'Weekly aggregation.', value: :week
      value 'MONTH', description: 'Monthly aggregation.', value: :month
    end
  end
end
