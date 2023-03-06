# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserWorker < ProjectRecalculateWorker
    data_consistency :always

    feature_category :system_access
    urgency :high
    queue_namespace :authorized_project_update

    deduplicate :until_executing, including_scheduled: true
    idempotent!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project && user

      in_lock(lock_key(project), ttl: 10.seconds) do
        AuthorizedProjectUpdate::ProjectRecalculatePerUserService.new(project, user).execute
      end
    end
  end
end
