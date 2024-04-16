# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateParamType < ::Types::BaseObject
      graphql_name 'MlCandidateParam'
      description 'Parameter for a candidate in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::CandidateParam], null: false, description: 'ID of the parameter.'

      field :name, ::GraphQL::Types::String,
        null: true,
        description: 'Name of the parameter.'

      field :value, ::GraphQL::Types::String,
        null: false,
        description: 'Value set for the parameter.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
