# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculateWorker
    include ApplicationWorker

    data_consistency :always
    include Gitlab::ExclusiveLeaseHelpers

    feature_category :system_access
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    def perform(project_id)
      project = Project.find_by_id(project_id)
      return unless project

      in_lock(lock_key(project), ttl: 10.seconds) do
        AuthorizedProjectUpdate::ProjectRecalculateService.new(project).execute
      end
    end

    private

    def lock_key(project)
      # The self.class.name.underscore value is hardcoded here as the prefix, so that the same
      # lock_key for this superclass will be used by the ProjectRecalculatePerUserWorker subclass.
      "authorized_project_update/project_recalculate_worker/projects/#{project.id}"
    end
  end
end
