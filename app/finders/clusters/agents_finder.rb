# frozen_string_literal: true

module Clusters
  class AgentsFinder
    include FinderMethods

    def initialize(object, current_user, params: {})
      @object = object
      @current_user = current_user
      @params = params
    end

    def execute
      return ::Clusters::Agent.none unless can_read_cluster_agents?

      agents = filter_clusters(object.cluster_agents)

      agents.ordered_by_name
    end

    private

    attr_reader :object, :current_user, :params

    def filter_clusters(agents)
      agents = agents.with_name(params[:name]) if params[:name].present?

      agents
    end

    def can_read_cluster_agents?
      current_user&.can?(:read_cluster_agent, object)
    end
  end
end

Clusters::AgentsFinder.prepend_mod_with('Clusters::AgentsFinder')
