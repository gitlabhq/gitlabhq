# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentTokensResolver < BaseResolver
      type Types::Clusters::AgentTokenType, null: true

      alias_method :agent, :object

      delegate :project, to: :agent

      argument :status, Types::Clusters::AgentTokenStatusEnum,
               required: false,
               description: 'Status of the token.'

      def resolve(**args)
        return ::Clusters::AgentToken.none unless can_read_agent_tokens?

        tokens = agent.last_used_agent_tokens
        tokens = tokens.with_status(args[:status]) if args[:status].present?

        tokens
      end

      private

      def can_read_agent_tokens?
        current_user.can?(:read_cluster, project)
      end
    end
  end
end
