# frozen_string_literal: true

module API
  module Entities
    class Environment < Entities::EnvironmentBasic
      include RequestAwareEntity

      expose :tier, documentation: { type: 'string', example: 'development' }
      expose :project, using: Entities::BasicProjectDetails
      expose :last_deployment, using: Entities::Deployment, if: { last_deployment: true }
      expose :state, documentation: { type: 'string', example: 'available' }
      expose :auto_stop_at, documentation: { type: 'dateTime', example: '2019-05-25T18:55:13.252Z' }
      expose :cluster_agent, using: Entities::Clusters::Agent, if: ->(_, _) { can_read_cluster_agent? }
      expose :kubernetes_namespace, if: ->(_, _) { can_read_cluster_agent? }
      expose :flux_resource_path, if: ->(_, _) { can_read_cluster_agent? }
      expose :description, documentation: { type: 'string', example: 'description' }
      expose :auto_stop_setting, documentation: { type: 'string', example: 'always' }

      private

      def can_read_cluster_agent?
        return unless object.cluster_agent.present?

        Ability.allowed?(options[:current_user], :read_cluster_agent, object.cluster_agent)
      end
    end
  end
end
