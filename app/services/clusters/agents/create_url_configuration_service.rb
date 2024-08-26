# frozen_string_literal: true

module Clusters
  module Agents
    class CreateUrlConfigurationService
      attr_reader :agent, :current_user, :params

      def initialize(agent:, current_user:, params:)
        @agent = agent
        @current_user = current_user
        @params = params
      end

      def execute
        return error_receptive_agents_disabled unless receptive_agents_enabled?
        return error_no_permissions unless cluster_agent_permissions?
        return error_already_receptive if agent.is_receptive

        config = ::Clusters::Agents::UrlConfiguration.new(
          agent: agent,
          project: project,
          created_by_user: current_user,
          url: params[:url],
          ca_cert: params[:ca_cert],
          tls_host: params[:tls_host]
        )

        if params[:client_key]
          config.client_key = params[:client_key]
          config.client_cert = params[:client_cert]
        else
          private_key = Ed25519::SigningKey.generate
          public_key = private_key.verify_key

          config.private_key = private_key.to_bytes
          config.public_key = public_key.to_bytes
        end

        if config.save
          ServiceResponse.new(status: :success, payload: { url_configuration: config }, reason: :created)
        else
          ServiceResponse.error(message: config.errors.full_messages)
        end
      end

      private

      delegate :project, to: :agent

      def cluster_agent_permissions?
        current_user.can?(:admin_pipeline, project) && current_user.can?(:create_cluster, project)
      end

      def receptive_agents_enabled?
        ::Gitlab::CurrentSettings.receptive_cluster_agents_enabled
      end

      def error_receptive_agents_disabled
        ServiceResponse.error(
          message: s_('ClusterAgent|Receptive agents are disabled for this GitLab instance')
        )
      end

      def error_already_receptive
        ServiceResponse.error(
          message: s_('ClusterAgent|URL configuration already exists for this agent')
        )
      end

      def error_no_permissions
        ServiceResponse.error(
          message: s_('ClusterAgent|You have insufficient permissions to create an url configuration for this agent')
        )
      end
    end
  end
end
