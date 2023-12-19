# frozen_string_literal: true

module Types
  module Ml
    # rubocop: disable Graphql/AuthorizeTypes -- authorization in ModelDetailsResolver
    class CandidateType < ::Types::BaseObject
      graphql_name 'MlCandidate'
      description 'Candidate for a model version in the model registry'

      connection_type_class Types::LimitedCountableConnectionType

      field :id, ::Types::GlobalIDType[::Ml::Candidate], null: false, description: 'ID of the candidate.'

      field :name, ::GraphQL::Types::String, null: false, description: 'Name of the candidate.'

      field :created_at, Types::TimeType, null: false, description: 'Date of creation.'

      field :_links, ::Types::Ml::CandidateLinksType, null: false, method: :itself,
        description: 'Map of links to perform actions on the candidate.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
