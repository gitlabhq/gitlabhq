# frozen_string_literal: true

module WorkItems
  class ProcessProjectTransferEventsWorker
    include Gitlab::EventStore::Subscriber

    data_consistency :sticky
    idempotent!
    deduplicate :until_executing, including_scheduled: true

    feature_category :portfolio_management
    concurrency_limit -> { 200 }

    def self.handles_event?(event)
      project = Project.find_by_id(event.data[:project_id])
      return unless project

      Feature.enabled?(:update_work_item_traversal_ids_on_transfer, project.project_namespace)
    end

    def handle_event(event)
      project = Project.find_by_id(event.data[:project_id])
      return unless project

      WorkItems::UpdateNamespaceTraversalIdsWorker.perform_async(project.project_namespace_id)
    end
  end
end
