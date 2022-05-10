# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectAccessChangedService
    def initialize(project_ids)
      @project_ids = Array.wrap(project_ids)
    end

    def execute(blocking: true)
      return if @project_ids.empty?

      bulk_args = @project_ids.map { |id| [id] }

      if blocking
        AuthorizedProjectUpdate::ProjectRecalculateWorker.bulk_perform_and_wait(bulk_args)
      else
        AuthorizedProjectUpdate::ProjectRecalculateWorker.bulk_perform_async(bulk_args) # rubocop:disable Scalability/BulkPerformWithContext
      end
    end
  end
end
