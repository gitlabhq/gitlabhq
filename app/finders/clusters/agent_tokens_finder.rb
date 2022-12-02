# frozen_string_literal: true

module Clusters
  class AgentTokensFinder
    include FinderMethods

    def initialize(agent, current_user, params = {})
      @agent = agent
      @current_user = current_user
      @params = params
    end

    def execute
      return ::Clusters::AgentToken.none unless can_read_cluster_agents?

      agent.agent_tokens.then { |agent_tokens| by_status(agent_tokens) }
    end

    private

    attr_reader :agent, :current_user, :params

    def by_status(agent_tokens)
      params[:status].present? ? agent_tokens.with_status(params[:status]) : agent_tokens
    end

    def can_read_cluster_agents?
      current_user&.can?(:read_cluster, agent&.project)
    end
  end
end
