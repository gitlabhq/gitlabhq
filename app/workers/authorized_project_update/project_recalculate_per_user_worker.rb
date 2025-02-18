# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserWorker < ProjectRecalculateWorker
    data_consistency :sticky, feature_flag: :change_data_consistency_for_permissions_workers

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project && user

      service = AuthorizedProjectUpdate::ProjectRecalculatePerUserService.new(project, user)

      recalculate(service)
    end
  end
end
