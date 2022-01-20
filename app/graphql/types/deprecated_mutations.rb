# frozen_string_literal: true

module Types
  module DeprecatedMutations
    extend ActiveSupport::Concern

    prepended do
      mount_mutation Mutations::Clusters::AgentTokens::Delete,
                     deprecated: { reason: 'Tokens must be revoked with ClusterAgentTokenRevoke', milestone: '14.7' }
    end
  end
end
