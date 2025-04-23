# frozen_string_literal: true

module Clusters
  module Agents
    module ManagedResources
      class DeleteWorker
        include ApplicationWorker
        include ClusterAgentQueue

        deduplicate :until_executed, including_scheduled: true
        idempotent!

        urgency :low
        data_consistency :delayed

        def perform(managed_resource_id, attempt = nil)
          managed_resource = Clusters::Agents::ManagedResource.find_by_id(managed_resource_id)
          return unless managed_resource.present?

          Clusters::Agents::ManagedResources::DeleteService.new(managed_resource, attempt_count: attempt).execute
        end
      end
    end
  end
end
