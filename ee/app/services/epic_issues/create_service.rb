module EpicIssues
  class CreateService < IssuableLinks::CreateService
    private

    def relate_issues(referenced_issue)
      link = EpicIssue.find_or_initialize_by(issue: referenced_issue)
      link.epic = issuable
      link.move_to_start
      link.save!

      link
    end

    def create_notes(referenced_issue)
      SystemNoteService.epic_issue(issuable, referenced_issue, current_user, :added)
      SystemNoteService.issue_on_epic(referenced_issue, issuable, current_user, :added)
    end

    def extractor_context
      { group: issuable.group }
    end

    def linkable_issues(issues)
      return [] unless can?(current_user, :admin_epic, issuable.group)

      issues.select { |issue| issuable_group_descendants.include?(issue.project.group) }
    end

    def issuable_group_descendants
      @descendants ||= issuable.group.self_and_descendants
    end
  end
end
