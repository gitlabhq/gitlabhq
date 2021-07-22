# frozen_string_literal: true

module Types
  module Metrics
    module Dashboards
      class AnnotationType < ::Types::BaseObject
        authorize :read_metrics_dashboard_annotation
        graphql_name 'MetricsDashboardAnnotation'

        field :description, GraphQL::Types::String, null: true,
              description: 'Description of the annotation.'

        field :id, GraphQL::Types::ID, null: false,
              description: 'ID of the annotation.'

        field :panel_id, GraphQL::Types::String, null: true,
              description: 'ID of a dashboard panel to which the annotation should be scoped.'

        field :starting_at, Types::TimeType, null: true,
              description: 'Timestamp marking start of annotated time span.'

        field :ending_at, Types::TimeType, null: true,
              description: 'Timestamp marking end of annotated time span.'

        def panel_id
          object.panel_xid
        end
      end
    end
  end
end
