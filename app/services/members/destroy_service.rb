# frozen_string_literal: true

module Members
  class DestroyService < Members::BaseService
    def execute(member, skip_authorization: false, skip_subresources: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_destroy_member?(member)

      @skip_auth = skip_authorization

      return member if member.is_a?(GroupMember) && member.source.last_owner?(member.user)

      member.destroy

      member.user&.invalidate_cache_counts

      if member.request? && member.user != current_user
        notification_service.decline_access_request(member)
      end

      delete_subresources(member) unless skip_subresources
      enqueue_delete_todos(member)

      after_execute(member: member)

      member
    end

    private

    def delete_subresources(member)
      return unless member.is_a?(GroupMember) && member.user && member.group

      delete_project_members(member)
      delete_subgroup_members(member)
    end

    def delete_project_members(member)
      groups = member.group.self_and_descendants

      ProjectMember.in_namespaces(groups).with_user(member.user).each do |project_member|
        self.class.new(current_user).execute(project_member, skip_authorization: @skip_auth)
      end
    end

    def delete_subgroup_members(member)
      groups = member.group.descendants

      GroupMember.of_groups(groups).with_user(member.user).each do |group_member|
        self.class.new(current_user).execute(group_member, skip_authorization: @skip_auth, skip_subresources: true)
      end
    end

    def can_destroy_member?(member)
      can?(current_user, destroy_member_permission(member), member)
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
