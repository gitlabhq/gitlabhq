# frozen_string_literal: true

module Types
  class EnvironmentType < BaseObject
    graphql_name 'Environment'
    description 'Describes where code is deployed for a project'

    present_using ::EnvironmentPresenter

    authorize :read_environment

    field :name, GraphQL::Types::String, null: false,
          description: 'Human-readable name of the environment.'

    field :id, GraphQL::Types::ID, null: false,
          description: 'ID of the environment.'

    field :state, GraphQL::Types::String, null: false,
          description: 'State of the environment, for example: available/stopped.'

    field :path, GraphQL::Types::String, null: false,
          description: 'The path to the environment.'

    field :metrics_dashboard, Types::Metrics::DashboardType, null: true,
          description: 'Metrics dashboard schema for the environment.',
          resolver: Resolvers::Metrics::DashboardResolver

    field :latest_opened_most_severe_alert,
          Types::AlertManagement::AlertType,
          null: true,
          description: 'The most severe open alert for the environment. If multiple alerts have equal severity, the most recent is returned.'
  end
end
