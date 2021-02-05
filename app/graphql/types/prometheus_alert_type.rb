# frozen_string_literal: true

module Types
  class PrometheusAlertType < BaseObject
    graphql_name 'PrometheusAlert'
    description 'The alert condition for Prometheus'

    authorize :read_prometheus_alerts

    present_using PrometheusAlertPresenter

    field :id, GraphQL::ID_TYPE, null: false,
          description: 'ID of the alert condition.'

    field :humanized_text,
          GraphQL::STRING_TYPE,
          null: false,
          description: 'The human-readable text of the alert condition.'
  end
end
