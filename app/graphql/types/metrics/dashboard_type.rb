# frozen_string_literal: true

module Types
  module Metrics
    # rubocop: disable Graphql/AuthorizeTypes
    # Authorization is performed at environment level
    class DashboardType < ::Types::BaseObject
      graphql_name 'MetricsDashboard'

      field :path, GraphQL::STRING_TYPE, null: true,
            description: 'Path to a file with the dashboard definition'

      field :annotations, Types::Metrics::Dashboards::AnnotationType.connection_type, null: true,
            description: 'Annotations added to the dashboard. Will always return `null` ' \
              'if `metrics_dashboard_annotations` feature flag is disabled',
            resolver: Resolvers::Metrics::Dashboards::AnnotationResolver
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
