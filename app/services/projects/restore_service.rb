# frozen_string_literal: true

module Projects
  class RestoreService < ::Namespaces::RestoreBaseService
    private

    def remove_permission
      :remove_project
    end

    def resource_name
      'project'
    end

    def execute_restore
      rename_resource
    end

    def post_success
      super

      ## Trigger root namespace statistics refresh, to add project_statistics of
      ## projects restored from deletion
      Namespaces::ScheduleAggregationWorker.perform_async(resource.namespace_id)
    end

    def rename_resource
      Project.transaction do
        transition_success = resource.cancel_deletion(transition_user: current_user)
        unless transition_success
          next ServiceResponse.error(message: resource.project_namespace.errors.full_messages.to_sentence)
        end

        update_service_response = ::Projects::UpdateService.new(
          resource,
          current_user,
          {
            archived: false,
            hidden: false,
            name: updated_value(resource.name),
            path: updated_value(resource.path),
            marked_for_deletion_at: nil,
            deleting_user: nil
          }
        ).execute

        ServiceResponse.from_legacy_hash(update_service_response)
      end
    end
  end
end
