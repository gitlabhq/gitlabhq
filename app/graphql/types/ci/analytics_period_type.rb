# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
    class AnalyticsPeriodType < BaseObject
      graphql_name 'PipelineAnalyticsPeriod'

      field :label, GraphQL::Types::String, null: true,
        alpha: { milestone: '17.5' },
        description: 'Label for the data point.'

      field :count, GraphQL::Types::BigInt, null: true,
        alpha: { milestone: '17.5' },
        description: 'Pipeline count, optionally filtered by status.' do
          argument :status,
            type: ::Types::Ci::AnalyticsJobStatusEnum,
            required: false,
            description: 'Filter totals by status. If not provided, the totals for all pipelines are returned.'
        end

      def count(status: :all)
        object.fetch(status, 0)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
