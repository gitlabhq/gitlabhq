# frozen_string_literal: true

module Clusters
  class DeployableAgentsFinder
    def initialize(project)
      @project = project
    end

    def execute
      project.cluster_agents.ordered_by_name
    end

    private

    attr_reader :project
  end
end
