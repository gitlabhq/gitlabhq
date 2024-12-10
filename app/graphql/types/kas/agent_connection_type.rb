# frozen_string_literal: true

module Types
  module Kas
    # rubocop: disable Graphql/AuthorizeTypes
    class AgentConnectionType < BaseObject
      graphql_name 'ConnectedAgent'
      description 'Connection details for an Agent'

      field :connected_at,
        Types::TimeType,
        null: true,
        description: 'When the connection was established.'

      field :connection_id,
        GraphQL::Types::BigInt,
        null: true,
        description: 'ID of the connection.'

      field :metadata,
        Types::Kas::AgentMetadataType,
        method: :agent_meta,
        null: true,
        description: 'Information about the Agent.'

      field :warnings,
        [Types::Kas::AgentWarningType],
        null: true,
        description: 'Agent warnings list.'

      def connected_at
        Time.at(object.connected_at.seconds)
      end
    end
    # rubocop: enable Graphql/AuthorizeTypes
  end
end
