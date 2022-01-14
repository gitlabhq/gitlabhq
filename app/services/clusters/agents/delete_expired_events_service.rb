# frozen_string_literal: true

module Clusters
  module Agents
    class DeleteExpiredEventsService
      def initialize(agent)
        @agent = agent
      end

      def execute
        agent.activity_events
          .recorded_before(remove_events_before)
          .each_batch { |batch| batch.delete_all }
      end

      private

      attr_reader :agent

      def remove_events_before
        agent.activity_event_deletion_cutoff
      end
    end
  end
end
