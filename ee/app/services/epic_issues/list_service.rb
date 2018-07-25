module EpicIssues
  class ListService < IssuableLinks::ListService
    private

    def issues
      return [] unless issuable&.group&.feature_available?(:epics)

      issuable.issues_readable_by(current_user)
    end

    def relation_path(issue)
      if can_admin_issue_link?(issue)
        group_epic_issue_path(issuable.group, issuable.iid, issue.epic_issue_id)
      end
    end

    def can_admin_issue_link?(issue)
      Ability.allowed?(current_user, :admin_epic_issue, issue) && Ability.allowed?(current_user, :admin_epic, issuable)
    end

    def reference(issue)
      issue.to_reference(full: true)
    end

    def to_hash(issue)
      super.merge(epic_issue_id: issue.epic_issue_id)
    end
  end
end
