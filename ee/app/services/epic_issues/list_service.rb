module EpicIssues
  class ListService < IssuableLinks::ListService
    private

    def issues
      issuable.issues(current_user)
    end

    def destroy_relation_path(issue)
      if can_destroy_issue_link?(issue)
        group_epic_issue_path(issuable.group, issuable.iid, issue.epic_issue_id)
      end
    end

    def can_destroy_issue_link?(issue)
      Ability.allowed?(current_user, :admin_issue_link, issue) && Ability.allowed?(current_user, :admin_epic, issuable)
    end

    def reference(issue)
      issue.to_reference(full: true)
    end
  end
end
