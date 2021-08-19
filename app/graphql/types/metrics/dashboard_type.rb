# frozen_string_literal: true

module Types
  module Metrics
    # rubocop: disable Graphql/AuthorizeTypes
    # Authorization is performed at environment level
    class DashboardType < ::Types::BaseObject
      graphql_name 'MetricsDashboard'

      field :path, GraphQL::Types::String, null: true,
            description: 'Path to a file with the dashboard definition.'

      field :schema_validation_warnings, [GraphQL::Types::String], null: true,
            description: 'Dashboard schema validation warnings.'

      field :annotations, Types::Metrics::Dashboards::AnnotationType.connection_type, null: true,
            description: 'Annotations added to the dashboard.',
            resolver: Resolvers::Metrics::Dashboards::AnnotationResolver

      # In order to maintain backward compatibility we need to return NULL when there are no warnings
      # and dashboard validation returns an empty array when there are no issues.
      def schema_validation_warnings
        warnings = object.schema_validation_warnings
        warnings unless warnings.empty?
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
