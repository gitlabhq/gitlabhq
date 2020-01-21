# frozen_string_literal: true

module Members
  class UpdateService < Members::BaseService
    # returns the updated member
    def execute(member, permission: :update)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, action_member_permission(permission, member), member)

      old_access_level = member.human_access
      old_expiry = member.expires_at

      if member.update(params)
        after_execute(action: permission, old_access_level: old_access_level, old_expiry: old_expiry, member: member)

        # Deletes only confidential issues todos for guests
        enqueue_delete_todos(member) if downgrading_to_guest?
      end

      member
    end

    private

    def downgrading_to_guest?
      params[:access_level] == Gitlab::Access::GUEST
    end
  end
end

Members::UpdateService.prepend_if_ee('EE::Members::UpdateService')
