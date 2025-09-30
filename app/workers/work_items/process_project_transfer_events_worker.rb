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
      Project.exists?(event.data[:project_id]) # rubocop: disable CodeReuse/ActiveRecord -- no need to initialize an object to find the Project
    end

    def handle_event(event)
      project = Project.find_by_id(event.data[:project_id])
      return unless project

      WorkItems::UpdateNamespaceTraversalIdsWorker.perform_async(project.project_namespace_id)
    end
  end
end
