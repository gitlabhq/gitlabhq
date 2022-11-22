# frozen_string_literal: true

module Clusters
  class AgentTokensFinder
    def initialize(agent, current_user)
      @agent = agent
      @current_user = current_user
    end

    def execute
      return ::Clusters::AgentToken.none unless can_read_cluster_agents?

      agent.agent_tokens
    end

    private

    attr_reader :agent, :current_user

    def can_read_cluster_agents?
      current_user&.can?(:read_cluster, agent&.project)
    end
  end
end
