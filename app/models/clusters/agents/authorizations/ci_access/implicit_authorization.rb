# frozen_string_literal: true

module Clusters
  module Agents
    module Authorizations
      module CiAccess
        class ImplicitAuthorization
          attr_reader :agent

          delegate :id, to: :agent, prefix: true

          def initialize(agent:)
            @agent = agent
          end

          def config_project
            agent.project
          end

          def config
            {}
          end
        end
      end
    end
  end
end
