# frozen_string_literal: true

# Deprecated:
#   All remaining references to this type always return nil.
#   Remove during any major release.
module Types
  module Metrics
    module Dashboards
      # rubocop:disable Graphql/AuthorizeTypes -- there is no object to authorize
      class AnnotationType < ::Types::BaseObject
        graphql_name 'MetricsDashboardAnnotation'

        field :description, GraphQL::Types::String, null: true,
          description: 'Description of the annotation.'

        field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the annotation.'

        field :panel_id,
          GraphQL::Types::String,
          null: true,
          description: 'ID of a dashboard panel to which the annotation should be scoped.',
          method: :panel_xid

        field :starting_at, Types::TimeType, null: true,
          description: 'Timestamp marking start of annotated time span.'

        field :ending_at, Types::TimeType, null: true,
          description: 'Timestamp marking end of annotated time span.'
      end
      # rubocop:enable Graphql/AuthorizeTypes
    end
  end
end
