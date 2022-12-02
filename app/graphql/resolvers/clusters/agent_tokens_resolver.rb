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
        ::Clusters::AgentTokensFinder.new(agent, current_user, args).execute
      end
    end
  end
end
