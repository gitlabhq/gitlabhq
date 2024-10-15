# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentsResolver < BaseResolver
      include LooksAhead

      type Types::Clusters::AgentType.connection_type, null: true

      extras [:lookahead]

      when_single do
        argument :name, GraphQL::Types::String,
          required: true,
          description: 'Name of the cluster agent.'
      end

      def resolve_with_lookahead(**args)
        apply_lookahead(
          ::Clusters::AgentsFinder
            .new(object, current_user, params: args)
            .execute
        )
      end

      private

      def preloads
        {
          activity_events: { activity_events: [{ user: [:user_detail, :user_preference] }, { agent_token: :agent }] },
          tokens: :active_agent_tokens
        }
      end
    end
  end
end

Resolvers::Clusters::AgentsResolver.prepend_mod_with('Resolvers::Clusters::AgentsResolver')
