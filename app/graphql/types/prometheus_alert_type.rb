# frozen_string_literal: true

# All references to this type are deprecated and always return nil,
# so this type should no longer be initialized
module Types
  class PrometheusAlertType < BaseObject
    graphql_name 'PrometheusAlert'
    description 'The alert condition for Prometheus'

    authorize :admin_operations

    field :id, GraphQL::Types::ID, null: false,
      description: 'ID of the alert condition.'

    field :humanized_text,
      GraphQL::Types::String,
      null: false,
      description: 'Human-readable text of the alert condition.'
  end
end
