# frozen_string_literal: true

module Clusters
  module Agents
    class CreateService < BaseService
      def execute
        return error_no_permissions unless cluster_agent_permissions?

        agent = ::Clusters::Agent.new(name: params[:name], project: project, created_by_user: current_user)

        if agent.save
          ServiceResponse.new(status: :success, payload: { cluster_agent: agent }, reason: :created)
        else
          ServiceResponse.error(message: agent.errors.full_messages)
        end
      end

      private

      def cluster_agent_permissions?
        current_user.can?(:admin_pipeline, project) && current_user.can?(:create_cluster, project)
      end

      def error_no_permissions
        ServiceResponse.error(
          message: s_('ClusterAgent|You have insufficient permissions to create a cluster agent for this project')
        )
      end
    end
  end
end

Clusters::Agents::CreateService.prepend_mod
