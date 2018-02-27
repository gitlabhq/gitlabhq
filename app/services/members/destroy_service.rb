module Members
  class DestroyService < Members::BaseService
    prepend EE::Members::DestroyService

    def execute(member, skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can_destroy_member?(member)

      return member if member.is_a?(GroupMember) && member.source.last_owner?(member.user)

      Member.transaction do
        unassign_issues_and_merge_requests(member) unless member.invite?
        member.notification_setting&.destroy

        member.destroy
      end

      if member.request? && member.user != current_user
        notification_service.decline_access_request(member)
      end

      after_execute(member: member)

      member
    end

    private

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

    def unassign_issues_and_merge_requests(member)
      if member.is_a?(GroupMember)
        issues = Issue.unscoped.select(1)
                 .joins(:project)
                 .where('issues.id = issue_assignees.issue_id AND projects.namespace_id = ?', member.source_id)

        # DELETE FROM issue_assignees WHERE user_id = X AND EXISTS (...)
        IssueAssignee.unscoped
          .where('user_id = :user_id AND EXISTS (:sub)', user_id: member.user_id, sub: issues)
          .delete_all

        MergeRequestsFinder.new(current_user, group_id: member.source_id, assignee_id: member.user_id)
          .execute
          .update_all(assignee_id: nil)
      else
        project = member.source

        # SELECT 1 FROM issues WHERE issues.id = issue_assignees.issue_id AND issues.project_id = X
        issues = Issue.unscoped.select(1)
                 .where('issues.id = issue_assignees.issue_id')
                 .where(project_id: project.id)

        # DELETE FROM issue_assignees WHERE user_id = X AND EXISTS (...)
        IssueAssignee.unscoped
          .where('user_id = :user_id AND EXISTS (:sub)', user_id: member.user_id, sub: issues)
          .delete_all

        project.merge_requests.opened.assigned_to(member.user).update_all(assignee_id: nil)
      end

      member.user.invalidate_cache_counts
    end
  end
end
