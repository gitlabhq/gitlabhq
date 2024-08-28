# frozen_string_literal: true

module Types
  module Clusters
    class AgentUrlConfigurationType < BaseObject
      graphql_name 'ClusterAgentUrlConfiguration'

      authorize :read_cluster_agent

      connection_type_class Types::CountableConnectionType

      field :cluster_agent,
        Types::Clusters::AgentType,
        description: 'Cluster agent of the URL configuration.',
        null: true

      field :id,
        ::Types::GlobalIDType[::Clusters::Agents::UrlConfiguration],
        null: false,
        description: 'Global ID of the URL configuration.'

      field :url,
        GraphQL::Types::String,
        null: true,
        description: 'URL of the URL configuration.'

      field :ca_cert,
        GraphQL::Types::String,
        null: true,
        description: 'CA certificate of the URL configuration. It is used to verify the agent endpoint.'

      field :tls_host,
        GraphQL::Types::String,
        null: true,
        description: 'TLS host of the URL configuration. ' \
          'It is used to verify the server name in the agent endpoint certificate.'

      field :public_key,
        GraphQL::Types::String,
        null: true,
        description: 'Public key if JWT authentication is used.'

      field :client_cert,
        GraphQL::Types::String,
        null: true,
        description: 'Client certificate if JWT authentication is used.'

      def cluster_agent
        Gitlab::Graphql::Loaders::BatchModelLoader.new(::Clusters::Agent, object.agent_id).find
      end
    end
  end
end
