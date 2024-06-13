# frozen_string_literal: true

module QA
  module Resource
    module Clusters
      class Agent < QA::Resource::Base
        attribute :id
        attribute :name
        attribute :project do
          QA::Resource::Project.fabricate_via_api! do |project|
            project.name = 'project-with-cluster-agent'
          end
        end

        def initialize
          @name = "my-agent"
        end

        def fabricate!; end

        def resource_web_url(resource)
          super
        rescue ResourceURLMissingError
          # this particular resource does not expose a web_url property
        end

        def api_get_path
          "/projects/#{project.id}/cluster_agents/#{id}"
        end

        def api_post_path
          "/projects/#{project.id}/cluster_agents"
        end

        def api_delete_path
          api_get_path
        end

        def api_post_body
          {
            id: project.id,
            name: name
          }
        end
      end
    end
  end
end
