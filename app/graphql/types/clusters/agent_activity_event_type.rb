# frozen_string_literal: true

module Types
  module Clusters
    class AgentActivityEventType < BaseObject
      graphql_name 'ClusterAgentActivityEvent'

      authorize :read_cluster_agent

      connection_type_class Types::CountableConnectionType

      field :recorded_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the event was recorded.'

      field :kind,
        GraphQL::Types::String,
        null: true,
        description: 'Type of event.'

      field :level,
        GraphQL::Types::String,
        null: true,
        description: 'Severity of the event.'

      field :user,
        Types::UserType,
        null: true,
        description: 'User associated with the event.'

      field :agent_token,
        Types::Clusters::AgentTokenType,
        null: true,
        description: 'Agent token associated with the event.'
    end
  end
end
