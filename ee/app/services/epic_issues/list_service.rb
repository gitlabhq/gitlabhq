module EpicIssues
  class ListService < IssuableLinks::ListService
    def execute
      issues.map do |referenced_issue|
        {
          id: referenced_issue.id,
          title: referenced_issue.title,
          state: referenced_issue.state,
          reference: reference(referenced_issue),
          path: project_issue_path(referenced_issue.project, referenced_issue.iid),
          destroy_relation_path: destroy_relation_path(referenced_issue),
          epic_issue_id: referenced_issue.epic_issue_id,
          position: referenced_issue.position
        }
      end
    end

    private

    def issues
      return [] unless issuable&.group&.feature_available?(:epics)

      issuable.issues(current_user)
    end

    def destroy_relation_path(issue)
      if can_destroy_issue_link?(issue)
        group_epic_issue_path(issuable.group, issuable.iid, issue.epic_issue_id)
      end
    end

    def can_destroy_issue_link?(issue)
      Ability.allowed?(current_user, :admin_epic_issue, issue) && Ability.allowed?(current_user, :admin_epic, issuable)
    end

    def reference(issue)
      issue.to_reference(full: true)
    end
  end
end
