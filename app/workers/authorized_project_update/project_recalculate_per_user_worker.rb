# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserWorker < ProjectRecalculateWorker
    data_consistency :always

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project && user

      service = AuthorizedProjectUpdate::ProjectRecalculatePerUserService.new(project, user)

      recalculate(project, service)
    end
  end
end
