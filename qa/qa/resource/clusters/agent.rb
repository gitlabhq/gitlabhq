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

        def fabricate!
          puts 'TODO: FABRICATE VIA UI'
        end
        # TODO
        #
        # The UI for this model is not yet implemented. So far it can only be
        # created through the GraphQL API
        # def fabricate
        #
        # end

        def api_get_path
          "gid://gitlab/Clusters::Agent/#{id}"
        end

        def api_post_path
          "/graphql"
        end

        def api_post_body
          <<~GQL
          mutation createAgent {
            createClusterAgent(input: { projectPath: "#{project.full_path}", name: "#{@name}" }) {
              clusterAgent {
                id
                name
              }
              errors
            }
          }
          GQL
        end
      end
    end
  end
end
