module Members
  class AuthorizedDestroyService < BaseService
    attr_accessor :member, :user

    def initialize(member, user = nil)
      @member, @user = member, user
    end

    def execute
      return false if member.is_a?(GroupMember) && member.source.last_owner?(member.user)

      Member.transaction do
        unassign_issues_and_merge_requests(member)

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
        issue_ids = IssuesFinder.new(user, group_id: member.source_id, assignee_id: member.user_id).
          execute.pluck(:id)

        IssueAssignee.delete_all(issue_id: issue_ids, user_id: member.user_id)

        MergeRequestsFinder.new(user, group_id: member.source_id, assignee_id: member.user_id).
          execute.
          update_all(assignee_id: nil)
      else
        project = member.source

        IssueAssignee.delete_all(
          user_id: member.user_id,
          issue_id: project.issues.opened.assigned_to(member.user).select(:id)
        )

        project.merge_requests.opened.assigned_to(member.user).update_all(assignee_id: nil)
      end

      member.user.invalidate_cache_counts
    end
  end
end
