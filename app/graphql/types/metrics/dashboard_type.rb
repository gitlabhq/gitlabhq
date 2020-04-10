# frozen_string_literal: true

module Types
  module Metrics
    # rubocop: disable Graphql/AuthorizeTypes
    # Authorization is performed at environment level
    class DashboardType < ::Types::BaseObject
      graphql_name 'MetricsDashboard'

      field :path, GraphQL::STRING_TYPE, null: true,
            description: 'Path to a file with the dashboard definition'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
