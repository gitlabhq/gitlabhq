# frozen_string_literal: true

module Types
  module Clusters
    class AgentType < BaseObject
      graphql_name 'ClusterAgent'

      authorize :read_cluster_agent

      connection_type_class Types::CountableConnectionType

      field :created_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the cluster agent was created.'

      field :created_by_user,
        Types::UserType,
        null: true,
        description: 'User object, containing information about the person who created the agent.'

      field :id, GraphQL::Types::ID,
        null: false,
        description: 'ID of the cluster agent.'

      field :name,
        GraphQL::Types::String,
        null: true,
        description: 'Name of the cluster agent.'

      field :project, Types::ProjectType,
        description: 'Project the cluster agent is associated with.',
        null: true,
        authorize: :read_project

      field :tokens,
        description: 'Tokens associated with the cluster agent.',
        null: true,
        resolver: ::Resolvers::Clusters::AgentTokensResolver

      field :updated_at,
        Types::TimeType,
        null: true,
        description: 'Timestamp the cluster agent was updated.'

      field :web_path,
        GraphQL::Types::String,
        null: true,
        description: 'Web path of the cluster agent.'

      field :connections,
        Types::Kas::AgentConnectionType.connection_type,
        null: true,
        description: 'Active connections for the cluster agent',
        complexity: 5,
        resolver: ::Resolvers::Kas::AgentConnectionsResolver

      field :activity_events,
        Types::Clusters::AgentActivityEventType.connection_type,
        null: true,
        description: 'Recent activity for the cluster agent.',
        resolver: Resolvers::Clusters::AgentActivityEventsResolver

      field :user_access_authorizations,
        Clusters::Agents::Authorizations::UserAccessType,
        null: true,
        description: 'User access config for the cluster agent.'

      def project
        Gitlab::Graphql::Loaders::BatchModelLoader.new(Project, object.project_id).find
      end

      def web_path
        ::Gitlab::Routing.url_helpers.project_cluster_agent_path(object.project, object.name)
      end
    end
  end
end

Types::Clusters::AgentType.prepend_mod
