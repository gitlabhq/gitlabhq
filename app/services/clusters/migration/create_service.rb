# frozen_string_literal: true

module Clusters
  module Migration
    class CreateService
      attr_reader :cluster, :clusterable, :current_user, :configuration_project, :agent_name

      def initialize(cluster, current_user:, configuration_project_id:, agent_name:)
        @cluster = cluster
        @clusterable = cluster.clusterable
        @current_user = current_user
        @configuration_project = find_configuration_project(configuration_project_id)
        @agent_name = agent_name
      end

      def execute
        validation_error = validate_inputs
        return validation_error if validation_error.present?

        agent_creation_response = agent_creation_service.execute
        return agent_creation_response unless agent_creation_response.success?

        agent = agent_creation_response[:cluster_agent]

        token_creation_response = token_creation_service(agent).execute
        return token_creation_response unless token_creation_response.success?

        migration = Clusters::AgentMigration.new(
          cluster: cluster,
          agent: agent,
          project: configuration_project,
          agent_name: agent_name
        )

        if migration.save
          Clusters::Migration::InstallAgentWorker.perform_async(migration.id)

          ServiceResponse.success
        else
          error_response(message: migration.errors.full_messages)
        end
      end

      private

      def validate_inputs
        message = if !feature_enabled?
                    _('Feature disabled')
                  elsif !current_user.can?(:admin_cluster, cluster)
                    _('Unauthorized')
                  elsif configuration_project.nil?
                    s_('ClusterIntegration|Invalid configuration project')
                  end

        error_response(message: message) if message
      end

      def agent_creation_service
        Clusters::Agents::CreateService.new(
          configuration_project,
          current_user,
          { name: agent_name }
        )
      end

      def token_creation_service(agent)
        Clusters::AgentTokens::CreateService.new(
          agent: agent,
          current_user: current_user,
          params: { name: agent_name }
        )
      end

      def find_configuration_project(project_id)
        return ::Project.find_by_id(project_id) if cluster.instance_type?

        # User permissions for this project are checked in Agents::CreateService
        clusterable.root_ancestor.all_projects.find_by_id(project_id)
      end

      def feature_enabled?
        Feature.enabled?(:cluster_agent_migrations, clusterable)
      end

      def error_response(message:)
        ServiceResponse.error(message: message)
      end
    end
  end
end
