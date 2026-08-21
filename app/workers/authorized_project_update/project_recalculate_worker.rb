# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateWorker
    include ApplicationWorker

    data_consistency :sticky
    include Gitlab::ExclusiveLeaseHelpers

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executed, if_deduplicated: :reschedule_once, including_scheduled: true

    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      service = AuthorizedProjectUpdate::ProjectRecalculateService.new(project)

      recalculate(service)
    end

    def recalculate(service)
      service.execute
    end

    private

    def lock_key(project)
      # The self.class.name.underscore value is hardcoded here as the prefix, so that the same
      # lock_key for this superclass will be used by the ProjectRecalculatePerUserWorker subclass.
      "authorized_project_update/project_recalculate_worker/projects/#{project.id}"
    end
  end
end
