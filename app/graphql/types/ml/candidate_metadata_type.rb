# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateMetadataType < ::Types::BaseObject
      graphql_name 'MlCandidateMetadata'
      description 'Metadata for a candidate in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::CandidateMetadata], null: false, description: 'ID of the metadata.'

      field :name, ::GraphQL::Types::String,
        null: true,
        description: 'Name of the metadata entry.'

      field :value, ::GraphQL::Types::String,
        null: false,
        description: 'Value set for the metadata entry.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
