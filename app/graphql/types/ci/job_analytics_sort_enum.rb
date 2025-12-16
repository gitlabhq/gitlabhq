# frozen_string_literal: true

module Types
  module Ci
    class JobAnalyticsSortEnum < BaseEnum
      graphql_name 'CiJobAnalyticsSort'
      description 'Values for sorting CI/CD job analytics'

      value 'NAME_ASC', 'Sort by name in ascending order.', value: :name_asc
      value 'NAME_DESC', 'Sort by name in descending order.', value: :name_desc

      value 'MEAN_DURATION_ASC',
        'Sort by mean duration in ascending order.',
        value: :mean_duration_asc

      value 'MEAN_DURATION_DESC',
        'Sort by mean duration in descending order.',
        value: :mean_duration_desc

      # rubocop:disable Graphql/EnumValues -- false positive, value is already defined in uppercase

      ClickHouse::Finders::Ci::FinishedBuildsFinder::ALLOWED_PERCENTILES.each do |percentile|
        value "P#{percentile}_DURATION_ASC",
          description: "Sort by #{percentile}th percentile duration in ascending order.",
          value: :"p#{percentile}_duration_asc"

        value "P#{percentile}_DURATION_DESC",
          description: "Sort by #{percentile}th percentile duration in descending order.",
          value: :"p#{percentile}_duration_desc"
      end

      # rubocop:enable Graphql/EnumValues

      value 'SUCCESS_RATE_ASC',
        'Sort by success rate in ascending order.',
        value: :rate_of_success_asc

      value 'SUCCESS_RATE_DESC',
        'Sort by success rate in descending order.',
        value: :rate_of_success_desc

      value 'FAILED_RATE_ASC',
        'Sort by failed rate in ascending order.',
        value: :rate_of_failed_asc

      value 'FAILED_RATE_DESC',
        'Sort by failed rate in descending order.',
        value: :rate_of_failed_desc

      value 'CANCELED_RATE_ASC',
        'Sort by canceled rate in ascending order.',
        value: :rate_of_canceled_asc

      value 'CANCELED_RATE_DESC',
        'Sort by canceled rate in descending order.',
        value: :rate_of_canceled_desc
    end
  end
end
