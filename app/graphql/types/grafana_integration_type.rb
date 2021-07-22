# frozen_string_literal: true

module Types
  class GrafanaIntegrationType < ::Types::BaseObject
    graphql_name 'GrafanaIntegration'

    authorize :admin_operations

    field :id, GraphQL::Types::ID, null: false,
      description: 'Internal ID of the Grafana integration.'
    field :grafana_url, GraphQL::Types::String, null: false,
      description: 'URL for the Grafana host for the Grafana integration.'
    field :enabled, GraphQL::Types::Boolean, null: false,
      description: 'Indicates whether Grafana integration is enabled.'
    field :created_at, Types::TimeType, null: false,
          description: 'Timestamp of the issue\'s creation.'
    field :updated_at, Types::TimeType, null: false,
          description: 'Timestamp of the issue\'s last activity.'
  end
end
