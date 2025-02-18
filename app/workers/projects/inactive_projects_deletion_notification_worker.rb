# frozen_string_literal: true

module Projects
  class InactiveProjectsDeletionNotificationWorker
    include ApplicationWorker
    include CronjobChildWorker
    include ExceptionBacktrace

    idempotent!
    data_consistency :sticky
    sidekiq_options retry: 3
    feature_category :groups_and_projects

    def perform(project_id, deletion_date)
      return if Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).notified?

      project = Project.find(project_id)

      notification_service.inactive_project_deletion_warning(project, deletion_date)

      Gitlab::InactiveProjectsDeletionWarningTracker.new(project_id).mark_notified
    rescue ActiveRecord::RecordNotFound => error
      Gitlab::ErrorTracking.log_exception(error, project_id: project_id)
    end

    private

    def notification_service
      @notification_service ||= NotificationService.new
    end
  end
end
