# frozen_string_literal: true

module AuthorizedProjectUpdate
  class ProjectRecalculatePerUserWorker < ProjectRecalculateWorker
    include Authz::UserRefreshLock

    data_consistency :sticky

    feature_category :permissions
    urgency :high
    queue_namespace :authorized_project_update

    idempotent!

    def perform(project_id, user_id)
      project = Project.find_by_id(project_id)
      user = User.find_by_id(user_id)

      return unless project && user

      service = AuthorizedProjectUpdate::ProjectRecalculatePerUserService.new(project, user)

      with_user_refresh_lock(user) { service.execute }
    rescue Gitlab::ExclusiveLeaseHelpers::FailedToObtainLockError
      reschedule_on_lock_contention(project_id, user_id)
    end
  end
end
