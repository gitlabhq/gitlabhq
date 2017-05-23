module Members
  class AuthorizedDestroyService < BaseService
    attr_accessor :member, :user

    def initialize(member, user = nil)
      @member, @user = member, user
    end

    def execute
      return false if member.is_a?(GroupMember) && member.source.last_owner?(member.user)

      Member.transaction do
        unassign_issues_and_merge_requests(member) unless member.invite?

        member.destroy
      end

      if member.request? && member.user != user
        notification_service.decline_access_request(member)
      end

      member
    end

    private

    def unassign_issues_and_merge_requests(member)
      if member.is_a?(GroupMember)
        issues = Issue.unscoped.select(1).
                 joins(:project).
                 where('issues.id = issue_assignees.issue_id AND projects.namespace_id = ?', member.source_id)

        # DELETE FROM issue_assignees WHERE user_id = X AND EXISTS (...)
        IssueAssignee.unscoped.
          where('user_id = :user_id AND EXISTS (:sub)', user_id: member.user_id, sub: issues).
          delete_all

        MergeRequestsFinder.new(user, group_id: member.source_id, assignee_id: member.user_id).
          execute.
          update_all(assignee_id: nil)
      else
        project = member.source

        # SELECT 1 FROM issues WHERE issues.id = issue_assignees.issue_id AND issues.project_id = X
        issues = Issue.unscoped.select(1).
                 where('issues.id = issue_assignees.issue_id').
                 where(project_id: project.id)

        # DELETE FROM issue_assignees WHERE user_id = X AND EXISTS (...)
        IssueAssignee.unscoped.
          where('user_id = :user_id AND EXISTS (:sub)', user_id: member.user_id, sub: issues).
          delete_all

        project.merge_requests.opened.assigned_to(member.user).update_all(assignee_id: nil)
      end

      member.user.invalidate_cache_counts
    end
  end
end
