# frozen_string_literal: true

module Types
  module Analytics
    module CycleAnalytics
      # rubocop: disable Graphql/AuthorizeTypes
      class MetricType < BaseObject
        graphql_name 'ValueStreamAnalyticsMetric'
        description ''

        field :value,
          GraphQL::Types::Float,
          null: true,
          description: 'Value for the metric.'

        field :identifier,
          GraphQL::Types::String,
          null: false,
          description: 'Identifier for the metric.'

        field :unit,
          GraphQL::Types::String,
          null: true,
          description: 'Unit of measurement.'

        field :title,
          GraphQL::Types::String,
          null: false,
          description: 'Title for the metric.'

        field :links,
          [LinkType],
          null: false,
          description: 'Optional links for drilling down.'
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
