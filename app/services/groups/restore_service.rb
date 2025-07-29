# frozen_string_literal: true

module Groups
  class RestoreService < ::Namespaces::RestoreBaseService
    private

    RenamingFailedError = Class.new(StandardError)
    DeletionScheduleDestroyingFailedError = Class.new(StandardError)

    def remove_permission
      :remove_group
    end

    def resource_name
      'group'
    end

    def execute_restore
      result = ServiceResponse.success

      resource.transaction do
        rename_resource!
        destroy_deletion_schedule!
      rescue RenamingFailedError
        result = ServiceResponse.error(message: resource.errors.full_messages.to_sentence)
        raise ActiveRecord::Rollback
      rescue DeletionScheduleDestroyingFailedError
        result = ServiceResponse.error(message: _('Could not restore the group'))
        raise ActiveRecord::Rollback
      end

      result
    end

    def rename_resource!
      successful = ::Groups::UpdateService.new(
        resource,
        current_user,
        { name: updated_value(resource.name), path: updated_value(resource.path) }
      ).execute
      return if successful

      raise RenamingFailedError
    end

    def destroy_deletion_schedule!
      return if resource.deletion_schedule.destroy

      raise DeletionScheduleDestroyingFailedError
    end
  end
end
