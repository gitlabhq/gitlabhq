# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
    class AnalyticsType < BaseObject
      graphql_name 'PipelineAnalytics'

      field :aggregate, Types::Ci::AnalyticsPeriodType, null: true,
        description: 'Pipeline analytics for the specified filter.', experiment: { milestone: '17.5' }

      field :time_series, [Types::Ci::AnalyticsPeriodType], null: true,
        experiment: { milestone: '17.9' },
        description:
          "Pipeline analytics shown over time based on the specified filter. " \
          "Data is aggregated in UTC, with adaptive resolution: hourly for 7-day windows or less, " \
          "daily for longer periods." do
            argument :period, Types::Ci::AnalyticsAggregationPeriodEnum, description: "Periodicity of aggregated data."
          end

      field :month_pipelines_labels, [GraphQL::Types::String], null: true,
        description: 'Labels for the monthly pipeline count.'
      field :month_pipelines_successful, [GraphQL::Types::Int], null: true,
        description: 'Total monthly successful pipeline count.'
      field :month_pipelines_totals, [GraphQL::Types::Int], null: true,
        description: 'Total monthly pipeline count.'
      field :pipeline_times_labels, [GraphQL::Types::String], null: true,
        description: 'Pipeline times labels.'
      field :pipeline_times_values, [GraphQL::Types::Int], null: true,
        description: 'Pipeline times.'
      field :week_pipelines_labels, [GraphQL::Types::String], null: true,
        description: 'Labels for the weekly pipeline count.'
      field :week_pipelines_successful, [GraphQL::Types::Int], null: true,
        description: 'Total weekly successful pipeline count.'
      field :week_pipelines_totals, [GraphQL::Types::Int], null: true,
        description: 'Total weekly pipeline count.'
      field :year_pipelines_labels, [GraphQL::Types::String], null: true,
        description: 'Labels for the yearly pipeline count.'
      field :year_pipelines_successful, [GraphQL::Types::Int], null: true,
        description: 'Total yearly successful pipeline count.'
      field :year_pipelines_totals, [GraphQL::Types::Int], null: true,
        description: 'Total yearly pipeline count.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
