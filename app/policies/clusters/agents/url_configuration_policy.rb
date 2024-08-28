# frozen_string_literal: true

module Clusters
  module Agents
    class UrlConfigurationPolicy < BasePolicy
      alias_method :agent_url_configuration, :subject

      delegate { agent_url_configuration.agent }
    end
  end
end
