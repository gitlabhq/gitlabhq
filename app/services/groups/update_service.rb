# frozen_string_literal: true

module Groups
  class UpdateService < Groups::BaseService
    include UpdateVisibilityLevel

    def execute
      reject_parent_id!
      remove_unallowed_params

      return false unless valid_visibility_level_change?(group, params[:visibility_level])

      return false unless valid_share_with_group_lock_change?

      before_assignment_hook(group, params)

      group.assign_attributes(params)

      begin
        success = group.save

        after_update if success

        success
      rescue Gitlab::UpdatePathError => e
        group.errors.add(:base, e.message)

        false
      end
    end

    private

    def before_assignment_hook(group, params)
      # overridden in EE
    end

    def after_update
      if group.previous_changes.include?(:visibility_level) && group.private?
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::GroupPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, group.id)
      end
    end

    def reject_parent_id!
      params.delete(:parent_id)
    end

    # overridden in EE
    def remove_unallowed_params
      params.delete(:emails_disabled) unless can?(current_user, :set_emails_disabled, group)
    end

    def valid_share_with_group_lock_change?
      return true unless changing_share_with_group_lock?
      return true if can?(current_user, :change_share_with_group_lock, group)

      group.errors.add(:share_with_group_lock, s_('GroupSettings|cannot be disabled when the parent group "Share with group lock" is enabled, except by the owner of the parent group'))
      false
    end

    def changing_share_with_group_lock?
      return false if params[:share_with_group_lock].nil?

      params[:share_with_group_lock] != group.share_with_group_lock
    end
  end
end
