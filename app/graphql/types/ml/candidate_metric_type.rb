# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateMetricType < ::Types::BaseObject
      graphql_name 'MlCandidateMetric'
      description 'Metric for a candidate in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::CandidateMetric], null: false, description: 'ID of the metric.'

      field :name, ::GraphQL::Types::String,
        null: true,
        description: 'Name of the metric.'

      field :step, ::GraphQL::Types::Int,
        null: false,
        description: 'Step at which the metric was measured.'

      field :value, ::GraphQL::Types::Float,
        null: false,
        description: 'Value set for the metric.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
