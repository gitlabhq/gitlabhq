# frozen_string_literal: true

module Clusters
  module Agents
    class DeleteUrlConfigurationService
      attr_reader :agent, :current_user, :url_configuration

      def initialize(agent:, current_user:, url_configuration:)
        @agent = agent
        @current_user = current_user
        @url_configuration = url_configuration
      end

      def execute
        return error_receptive_agents_disabled unless receptive_agents_enabled?
        return error_no_permissions unless current_user.can?(:admin_cluster, agent)

        if url_configuration.destroy
          ServiceResponse.success
        else
          ServiceResponse.error(message: url_configuration.errors.full_messages)
        end
      end

      private

      delegate :project, to: :agent

      def error_no_permissions
        ServiceResponse.error(
          message: s_('ClusterAgent|You have insufficient permissions to delete this agent url configuration'))
      end

      def receptive_agents_enabled?
        ::Gitlab::CurrentSettings.receptive_cluster_agents_enabled
      end

      def error_receptive_agents_disabled
        ServiceResponse.error(
          message: s_('ClusterAgent|Receptive agents are disabled for this GitLab instance')
        )
      end
    end
  end
end
