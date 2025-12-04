# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this represents a hash, from the computed percentiles query
    class DurationStatisticsType < BaseObject
      graphql_name 'CiDurationStatistics'
      description 'Histogram of durations for a group of CI/CD jobs or pipelines.'

      PERCENTILES = ::Ci::CollectPipelineAnalyticsServiceBase::ALLOWED_PERCENTILES

      field :mean, Types::DurationType,
        null: true, description: 'Mean (average) duration.',
        experiment: { milestone: '18.7' }

      PERCENTILES.each do |p|
        field :"p#{p}", Types::DurationType,
          null: true, description: "#{p}th percentile. #{p}% of the durations are lower than this value.",
          experiment: { milestone: '15.8' }, hash_key: :"p#{p}"
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
