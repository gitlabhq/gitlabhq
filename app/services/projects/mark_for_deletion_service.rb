# frozen_string_literal: true

module Projects
  class MarkForDeletionService < ::Namespaces::MarkForDeletionBaseService
    private

    def remove_permission
      :remove_project
    end

    def notification_method
      :project_scheduled_for_deletion
    end

    def resource_name
      'project'
    end

    def execute_deletion
      result = nil

      Project.transaction do
        transition_success = resource.schedule_deletion(transition_user: current_user)
        unless transition_success
          result = ServiceResponse.error(message: resource.project_namespace.errors.full_messages.to_sentence)
          raise ActiveRecord::Rollback
        end

        update_service_response = ::Projects::UpdateService.new(
          resource,
          current_user,
          update_service_params
        ).execute

        result = ServiceResponse.from_legacy_hash(update_service_response)
        raise ActiveRecord::Rollback if result.error?
      end

      result
    end

    def update_service_params
      {
        archived: true,
        name: suffixed_identifier(resource.name),
        path: suffixed_identifier(resource.path),
        marked_for_deletion_at: Time.current,
        deleting_user: current_user
      }
    end

    def post_success
      super

      ## Trigger root statistics refresh, to skip project_statistics of
      ## projects marked for deletion
      ::Namespaces::ScheduleAggregationWorker.perform_async(resource.namespace_id)
    end
  end
end

Projects::MarkForDeletionService.prepend_mod
