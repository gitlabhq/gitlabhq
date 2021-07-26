# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes
    class AnalyticsType < BaseObject
      graphql_name 'PipelineAnalytics'

      field :week_pipelines_totals, [GraphQL::Types::Int], null: true,
            description: 'Total weekly pipeline count.'
      field :week_pipelines_successful, [GraphQL::Types::Int], null: true,
            description: 'Total weekly successful pipeline count.'
      field :week_pipelines_labels, [GraphQL::Types::String], null: true,
            description: 'Labels for the weekly pipeline count.'
      field :month_pipelines_totals, [GraphQL::Types::Int], null: true,
            description: 'Total monthly pipeline count.'
      field :month_pipelines_successful, [GraphQL::Types::Int], null: true,
            description: 'Total monthly successful pipeline count.'
      field :month_pipelines_labels, [GraphQL::Types::String], null: true,
            description: 'Labels for the monthly pipeline count.'
      field :year_pipelines_totals, [GraphQL::Types::Int], null: true,
            description: 'Total yearly pipeline count.'
      field :year_pipelines_successful, [GraphQL::Types::Int], null: true,
            description: 'Total yearly successful pipeline count.'
      field :year_pipelines_labels, [GraphQL::Types::String], null: true,
            description: 'Labels for the yearly pipeline count.'
      field :pipeline_times_values, [GraphQL::Types::Int], null: true,
            description: 'Pipeline times.'
      field :pipeline_times_labels, [GraphQL::Types::String], null: true,
            description: 'Pipeline times labels.'
    end
  end
end
