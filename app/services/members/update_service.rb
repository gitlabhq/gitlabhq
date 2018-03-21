module Members
  class UpdateService < Members::BaseService
    # returns the updated member
    def execute(member, permission: :update)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, action_member_permission(permission, member), member)

      old_access_level = member.human_access

      if member.update_attributes(params)
        after_execute(action: permission, old_access_level: old_access_level, member: member)
      end

      member
    end
  end
end
