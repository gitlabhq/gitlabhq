# frozen_string_literal: true

module Types
  module Kas
    # rubocop: disable Graphql/AuthorizeTypes
    class AgentMetadataType < BaseObject
      graphql_name 'AgentMetadata'
      description 'Information about a connected Agent'

      field :version,
        GraphQL::Types::String,
        null: true,
        description: 'Agent version tag.'

      field :commit,
        GraphQL::Types::String,
        method: :commit_id,
        null: true,
        description: 'Agent version commit.'

      field :pod_namespace,
        GraphQL::Types::String,
        null: true,
        description: 'Namespace of the pod running the Agent.'

      field :pod_name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of the pod running the Agent.'
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
