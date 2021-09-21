# frozen_string_literal: true

module Clusters
  class AgentsFinder
    def initialize(project, current_user, params: {})
      @project = project
      @current_user = current_user
      @params = params
    end

    def execute
      return ::Clusters::Agent.none unless can_read_cluster_agents?

      agents = project.cluster_agents
      agents = agents.with_name(params[:name]) if params[:name].present?

      agents.ordered_by_name
    end

    private

    attr_reader :project, :current_user, :params

    def can_read_cluster_agents?
      current_user.can?(:read_cluster, project)
    end
  end
end
