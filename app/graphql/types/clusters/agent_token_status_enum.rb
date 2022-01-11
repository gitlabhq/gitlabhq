# frozen_string_literal: true

module Types
  module Clusters
    class AgentTokenStatusEnum < BaseEnum
      graphql_name 'AgentTokenStatus'
      description 'Agent token statuses'

      ::Clusters::AgentToken.statuses.keys.each do |status|
        value status.upcase, value: status, description: "#{status.titleize} agent token."
      end
    end
  end
end
