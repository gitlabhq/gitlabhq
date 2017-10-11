module Members
  class DestroyService < Members::BaseService
    prepend EE::Members::DestroyService

    def execute(member)
      raise Gitlab::Access::AccessDeniedError unless can_destroy_member?(member)

      AuthorizedDestroyService.new(current_user).execute(member)

      after_execute(member: member)

      member
    end

    private

    def can_destroy_member?(member)
      member && can?(current_user, destroy_member_permission(member), member)
    end

    def destroy_member_permission(member)
      case member
      when GroupMember
        :destroy_group_member
      when ProjectMember
        :destroy_project_member
      else
        raise "Unknown member type: #{member}!"
      end
    end
  end
end
