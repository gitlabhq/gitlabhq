# frozen_string_literal: true

module Groups
  class MarkForDeletionService < ::Namespaces::MarkForDeletionBaseService
    RenamingFailedError = Class.new(StandardError)
    DeletionScheduleSavingFailedError = Class.new(StandardError)

    private

    def remove_permission
      :remove_group
    end

    def notification_method
      :group_scheduled_for_deletion
    end

    def resource_name
      'group'
    end

    def execute_deletion
      deletion_schedule = resource.build_deletion_schedule(
        marked_for_deletion_on: Time.current,
        deleting_user: current_user
      )

      result = ServiceResponse.success

      resource.transaction do
        rename_group_for_deletion!
        save_deletion_schedule!(deletion_schedule)
      rescue RenamingFailedError
        result = ServiceResponse.error(message: resource.errors.full_messages.to_sentence)
        raise ActiveRecord::Rollback
      rescue DeletionScheduleSavingFailedError
        result = ServiceResponse.error(message: deletion_schedule.errors.full_messages.to_sentence)
        raise ActiveRecord::Rollback
      end

      result
    end

    def rename_group_for_deletion!
      return unless rename_group_for_deletion?

      successful = ::Groups::UpdateService.new(
        resource,
        current_user,
        update_service_params
      ).execute
      return if successful

      raise RenamingFailedError
    end

    def rename_group_for_deletion?
      !resource.has_container_repository_including_subgroups?
    end

    def update_service_params
      {
        name: suffixed_identifier(resource.name),
        path: suffixed_identifier(resource.path)
      }
    end

    def save_deletion_schedule!(deletion_schedule)
      return if deletion_schedule.save

      raise DeletionScheduleSavingFailedError
    end
  end
end
