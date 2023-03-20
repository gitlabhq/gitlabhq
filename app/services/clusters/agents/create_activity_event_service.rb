# frozen_string_literal: true

module Clusters
  module Agents
    class CreateActivityEventService
      def initialize(agent, **params)
        @agent = agent
        @params = params
      end

      def execute
        agent.activity_events.create!(params)

        DeleteExpiredEventsWorker.perform_at(schedule_cleanup_at, agent.id)

        ServiceResponse.success
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, agent_id: agent.id)

        ServiceResponse.error(message: e.message)
      end

      private

      attr_reader :agent, :params

      def schedule_cleanup_at
        1.hour.from_now.change(min: agent.id % 60)
      end
    end
  end
end
