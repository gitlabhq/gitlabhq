# frozen_string_literal: true

module Members
  class UpdateService < Members::BaseService
    # returns the updated member
    def execute(member, permission: :update)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, action_member_permission(permission, member), member)
      raise Gitlab::Access::AccessDeniedError if prevent_upgrade_to_owner?(member) || prevent_downgrade_from_owner?(member)

      return success(member: member) if update_results_in_no_change?(member)

      old_access_level = member.human_access
      old_expiry = member.expires_at

      if member.update(params)
        after_execute(action: permission, old_access_level: old_access_level, old_expiry: old_expiry, member: member)

        # Deletes only confidential issues todos for guests
        enqueue_delete_todos(member) if downgrading_to_guest?
      end

      if member.errors.any?
        error(member.errors.full_messages.to_sentence, pass_back: { member: member })
      else
        success(member: member)
      end
    end

    private

    def update_results_in_no_change?(member)
      return false if params[:expires_at]&.to_date != member.expires_at
      return false if params[:access_level] != member.access_level

      true
    end

    def downgrading_to_guest?
      params[:access_level] == Gitlab::Access::GUEST
    end

    def upgrading_to_owner?
      params[:access_level] == Gitlab::Access::OWNER
    end

    def downgrading_from_owner?(member)
      member.owner?
    end

    def prevent_upgrade_to_owner?(member)
      upgrading_to_owner? && cannot_assign_owner_responsibilities_to_member_in_project?(member)
    end

    def prevent_downgrade_from_owner?(member)
      downgrading_from_owner?(member) && cannot_revoke_owner_responsibilities_from_member_in_project?(member)
    end
  end
end

Members::UpdateService.prepend_mod_with('Members::UpdateService')
