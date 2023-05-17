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
      return ::Clusters::AgentToken.none unless can_read_cluster_agent?

      agent_tokens_by_status
    end

    private

    attr_reader :agent, :current_user, :params

    def agent_tokens_by_status
      # If the `status` parameter is set to `active`, we use the `active_agent_tokens` scope
      # in case this called from GraphQL's AgentTokensResolver. This prevents a repeat query
      # to the database, because `active_agent_tokens` is already preloaded in the AgentsResolver
      return agent.active_agent_tokens if active_tokens_only?

      # Else, we use the `agent_tokens` scope combined with `with_status` if necessary
      params[:status].present? ? agent.agent_tokens.with_status(params[:status]) : agent.agent_tokens
    end

    def active_tokens_only?
      params[:status].present? && params[:status].to_sym == :active
    end

    def can_read_cluster_agent?
      current_user&.can?(:read_cluster_agent, agent)
    end
  end
end
