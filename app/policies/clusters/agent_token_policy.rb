# frozen_string_literal: true

module Clusters
  class AgentTokenPolicy < BasePolicy
    alias_method :token, :subject

    delegate { token.agent }
  end
end
