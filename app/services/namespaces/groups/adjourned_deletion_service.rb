# frozen_string_literal: true

# This service manages the group deletion process:
# - Permanently deletes the group if user has sufficient permissions.
# - Restores the group if user lacks necessary permissions.
# Note: This service should only be called from a Sidekiq context otherwise,
# `Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode` will raise an error.
module Namespaces
  module Groups
    class AdjournedDeletionService < ::BaseGroupService
      def execute
        if can_current_user_remove_group?
          delete_group
        else
          restore_group
        end
      end

      private

      def can_current_user_remove_group?
        Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(current_user) do
          current_user.can?(:remove_group, group)
        end
      end

      def delete_group
        GroupDestroyWorker.perform_in(params[:delay], group.id, current_user.id)
      end

      def restore_group
        admin_bot = ::Users::Internal.admin_bot
        Gitlab::Auth::CurrentUserMode.optionally_run_in_admin_mode(admin_bot) do
          ::Groups::RestoreService.new(group, admin_bot).execute
        end
      end
    end
  end
end
