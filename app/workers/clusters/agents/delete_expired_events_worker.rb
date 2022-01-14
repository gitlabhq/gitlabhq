# frozen_string_literal: true

module Clusters
  module Agents
    class DeleteExpiredEventsWorker
      include ApplicationWorker
      include ClusterAgentQueue

      deduplicate :until_executed, including_scheduled: true
      idempotent!

      data_consistency :always

      def perform(agent_id)
        if agent = Clusters::Agent.find_by_id(agent_id)
          Clusters::Agents::DeleteExpiredEventsService.new(agent).execute
        end
      end
    end
  end
end
