# frozen_string_literal: true

module Groups
  class UpdateService < Groups::BaseService
    include UpdateVisibilityLevel

    def execute
      reject_parent_id!

      return false unless valid_visibility_level_change?(group, params[:visibility_level])

      return false unless valid_share_with_group_lock_change?

      group.assign_attributes(params)

      begin
        after_update if group.save

        true
      rescue Gitlab::UpdatePathError => e
        group.errors.add(:base, e.message)

        false
      end
    end

    private

    def after_update
      if group.previous_changes.include?(:visibility_level) && group.private?
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::GroupPrivateWorker.perform_in(1.hour, group.id)
      end
    end

    def reject_parent_id!
      params.except!(:parent_id)
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
