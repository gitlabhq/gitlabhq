module EpicIssues
  class CreateService < IssuableLinks::CreateService
    private

    def relate_issues(referenced_issue)
      link = EpicIssue.find_or_initialize_by(issue: referenced_issue)
      link.epic = issuable
      link.save
    end

    def create_notes?
      false
    end

    def extractor_context
      { group: issuable.group }
    end

    def linkable_issues(issues)
      issues.select { |issue| can?(current_user, :admin_epic_issue, issue) && issue.project.group == issuable.group }
    end
  end
end
