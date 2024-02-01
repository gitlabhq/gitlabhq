# frozen_string_literal: true

module Types
  # rubocop: disable Graphql/AuthorizeTypes -- The resolver authorizes the request
  class ProjectPlanLimitsType < BaseObject
    graphql_name 'ProjectPlanLimits'
    description 'Plan limits for the current project.'

    field :ci_pipeline_schedules, GraphQL::Types::Int, null: true,
      description: 'Maximum number of pipeline schedules allowed per project.'
  end
  # rubocop: enable Graphql/AuthorizeTypes
end
