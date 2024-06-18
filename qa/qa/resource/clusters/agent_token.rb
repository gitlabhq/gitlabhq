# frozen_string_literal: true

module QA
  module Resource
    module Clusters
      class AgentToken < QA::Resource::Base
        attribute :id
        attribute :token
        attribute :agent do
          QA::Resource::Clusters::Agent.fabricate_via_api!
        end

        def fabricate!; end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "/projects/#{agent.project.id}/cluster_agents/#{agent.id}/tokens/#{id}"
        end

        def api_post_path
          "/projects/#{agent.project.id}/cluster_agents/#{agent.id}/tokens"
        end

        def api_delete_path
          api_get_path
        end

        def api_post_body
          {
            id: agent.project.id,
            agent_id: agent.id,
            name: agent.name
          }
        end
      end
    end
  end
end
