# frozen_string_literal: true

module Clusters
  class AgentPolicy < BasePolicy
    alias_method :cluster_agent, :subject

    delegate { cluster_agent.project }
  end
end
