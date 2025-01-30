# frozen_string_literal: true

module Types
  module Ci
    # rubocop: disable Graphql/AuthorizeTypes -- this type is authorized by the resolver
    class AnalyticsPeriodType < BaseObject
      graphql_name 'PipelineAnalyticsPeriod'

      field :label, ::Types::DateType, null: true,
        experiment: { milestone: '17.5' },
        description: 'Data point label (UTC time).'

      field :count, GraphQL::Types::BigInt, null: true,
        experiment: { milestone: '17.5' },
        description: 'Pipeline count, optionally filtered by status.' do
          argument :status,
            type: ::Types::Ci::AnalyticsJobStatusEnum,
            required: true,
            default_value: :any,
            description: 'Filter pipeline totals by status. ' \
              'If not specified, totals for all pipeline statuses are returned.'
        end

      field :duration_statistics, ::Types::Ci::DurationStatisticsType, null: true,
        description: 'Pipeline duration statistics.',
        experiment: { milestone: '17.5' }

      def count(status:)
        object[:count].fetch(status, 0)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
