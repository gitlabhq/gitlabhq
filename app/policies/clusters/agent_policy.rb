# frozen_string_literal: true

module Clusters
  class AgentPolicy < BasePolicy
    alias_method :cluster_agent, :subject

    delegate { cluster_agent.project }

    # This condition is more expensive than the same permission check in ProjectPolicy,
    # so having a higher score.
    condition(:ci_access_authorized_agent, score: 10) do
      @subject.ci_access_authorized_for?(@user)
    end

    condition(:user_access_authorized_agent, score: 10) do
      @subject.user_access_authorized_for?(@user)
    end

    rule { ci_access_authorized_agent | user_access_authorized_agent }.policy do
      enable :read_cluster_agent
    end
  end
end

Clusters::AgentPolicy.prepend_mod_with('Clusters::AgentPolicy')
