# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsAggregationEnum < BaseEnum
      graphql_name 'CiJobAnalyticsAggregation'
      description 'Aggregation functions available for CI/CD job analytics'

      value 'MEAN_DURATION_IN_SECONDS',
        value: :mean_duration_in_seconds,
        description: 'Average duration of jobs in seconds.'

      value 'P95_DURATION_IN_SECONDS',
        value: :p95_duration_in_seconds,
        description: '95th percentile duration of jobs in seconds.'

      value 'RATE_OF_SUCCESS',
        value: :rate_of_success,
        description: 'Percentage of successful jobs.'

      value 'RATE_OF_FAILED',
        value: :rate_of_failed,
        description: 'Percentage of failed jobs.'

      value 'RATE_OF_CANCELED',
        value: :rate_of_canceled,
        description: 'Percentage of canceled jobs.'
    end
  end
end
