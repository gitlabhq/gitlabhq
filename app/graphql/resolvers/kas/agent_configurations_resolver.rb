# frozen_string_literal: true

module Resolvers
  module Kas
    class AgentConfigurationsResolver < BaseResolver
      type Types::Kas::AgentConfigurationType.connection_type, null: true

      # Calls Gitaly via KAS
      calls_gitaly!

      alias_method :project, :object

      def resolve
        return [] unless can_read_agent_configuration?

        kas_client.list_agent_config_files(project: project)
      rescue GRPC::BadStatus, Gitlab::Kas::Client::ConfigurationError => e
        raise Gitlab::Graphql::Errors::ResourceNotAvailable, e.class.name
      end

      private

      def can_read_agent_configuration?
        current_user.can?(:read_cluster_agent, project)
      end

      def kas_client
        @kas_client ||= Gitlab::Kas::Client.new
      end
    end
  end
end
