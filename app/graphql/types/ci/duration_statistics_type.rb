# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this represents a hash, from the computed percentiles query
    class DurationStatisticsType < BaseObject
      graphql_name 'CiDurationStatistics'
      description 'Histogram of durations for a group of CI/CD jobs or pipelines.'

      PERCENTILES = ::Ci::CollectPipelineAnalyticsServiceBase::ALLOWED_PERCENTILES

      PERCENTILES.each do |p|
        field "p#{p}", Types::DurationType,
          null: true, description: "#{p}th percentile. #{p}% of the durations are lower than this value.",
          experiment: { milestone: '15.8' }

        define_method(:"p#{p}") do
          object[:"p#{p}"]
        end
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
