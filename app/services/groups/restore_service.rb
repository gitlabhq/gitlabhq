# frozen_string_literal: true

module Groups # rubocop:disable Gitlab/BoundedContexts -- existing top-level module
  class RestoreService < Groups::BaseService
    def execute
      return error(_('You are not authorized to perform this action')) unless can?(current_user, :remove_group, group)
      return error(_('Group has not been marked for deletion')) unless group.marked_for_deletion?
      return error(_('Group deletion is in progress')) if group.deleted?

      result = remove_deletion_schedule

      group.reset

      log_event if result[:status] == :success

      result
    end

    private

    def remove_deletion_schedule
      deletion_schedule = group.deletion_schedule

      if deletion_schedule.destroy
        success
      else
        error(_('Could not restore the group'))
      end
    end

    def log_event
      log_info("User #{current_user.id} restored group #{group.full_path}")
    end
  end
end

Groups::RestoreService.prepend_mod
