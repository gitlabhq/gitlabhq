# frozen_string_literal: true

module Projects
  class MarkForDeletionService < BaseService
    def execute
      return success if project.marked_for_deletion_at?

      result = ::Projects::UpdateService.new(
        project,
        current_user,
        project_update_service_params
      ).execute
      log_error(result[:message]) if result[:status] == :error

      if result[:status] == :success
        log_event
        send_project_deletion_notification

        ## Trigger root statistics refresh, to skip project_statistics of
        ## projects marked for deletion
        ::Namespaces::ScheduleAggregationWorker.perform_async(project.namespace_id)
      end

      result
    end

    private

    def send_project_deletion_notification
      return unless project.adjourned_deletion?

      ::NotificationService.new.project_scheduled_for_deletion(project)
    end

    def log_event
      log_info("User #{current_user.id} marked project #{project.full_path} for deletion")
    end

    def project_update_service_params
      {
        archived: true,
        name: "#{project.name}-deleted-#{project.id}",
        path: "#{project.path}-deleted-#{project.id}",
        marked_for_deletion_at: Time.current.utc,
        deleting_user: current_user
      }
    end
  end
end

Projects::MarkForDeletionService.prepend_mod
