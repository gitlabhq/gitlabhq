# frozen_string_literal: true

module Resolvers
  module Clusters
    class AgentActivityEventsResolver < BaseResolver
      type Types::Clusters::AgentActivityEventType, null: true

      alias_method :agent, :object

      delegate :project, to: :agent

      def resolve(**args)
        return ::Clusters::Agents::ActivityEvent.none unless can_view_activity_events?

        agent.activity_events
      end

      private

      def can_view_activity_events?
        current_user.can?(:admin_cluster, project)
      end
    end
  end
end
