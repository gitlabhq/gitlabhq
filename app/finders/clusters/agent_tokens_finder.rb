# frozen_string_literal: true

module Clusters
  class AgentTokensFinder
    def initialize(object, current_user, agent_id)
      @object = object
      @current_user = current_user
      @agent_id = agent_id
    end

    def execute
      raise_not_found_unless_can_read_cluster

      object.cluster_agents.find(agent_id).agent_tokens
    end

    private

    attr_reader :object, :current_user, :agent_id

    def raise_not_found_unless_can_read_cluster
      raise ActiveRecord::RecordNotFound unless current_user&.can?(:read_cluster, object)
    end
  end
end
