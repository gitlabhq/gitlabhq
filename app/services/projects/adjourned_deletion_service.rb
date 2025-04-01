# frozen_string_literal: true

# This service manages the project deletion process:
# - Permanently deletes the project if user has sufficient permissions.
# - Restores the project if user lacks necessary permissions.
# Note: This service should only be called from a Sidekiq context otherwise,
# `Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode` will raise an error.
module Projects
  class AdjournedDeletionService < ::BaseProjectService
    def execute
      if can_current_user_remove_project?
        delete_project
      else
        restore_project
      end
    end

    private

    def can_current_user_remove_project?
      return false unless current_user

      Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(current_user) do
        current_user.can?(:remove_project, project)
      end
    end

    def delete_project
      ::Projects::DestroyService.new(project, current_user).async_execute
    end

    def restore_project
      admin_bot = ::Users::Internal.admin_bot
      Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(admin_bot) do
        ::Projects::RestoreService.new(project, admin_bot).execute
      end
    end
  end
end
