# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentTokensResolver < BaseResolver
      type Types::Clusters::AgentTokenType.connection_type, null: true

      alias_method :agent, :object

      delegate :project, to: :agent

      def resolve(**_args)
        ::Clusters::AgentTokensFinder.new(agent, current_user, status: :active).execute
      end
    end
  end
end
