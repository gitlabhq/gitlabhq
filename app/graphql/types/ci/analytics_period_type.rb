# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
    class AnalyticsPeriodType < BaseObject
      graphql_name 'PipelineAnalyticsPeriod'

      field :labels, [GraphQL::Types::String], null: true,
        description: 'Labels for the pipeline count.'
      field :totals, [GraphQL::Types::Int], null: true,
        description: 'Total pipeline count, optionally filtered by status.' do
          argument :status,
            type: ::Types::Ci::AnalyticsJobStatusEnum,
            required: false,
            description: 'Filter totals by status. If not provided, the totals for all pipelines are returned.'
        end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
