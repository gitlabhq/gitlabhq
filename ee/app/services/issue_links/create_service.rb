module IssueLinks
  class CreateService < IssuableLinks::CreateService
    def relate_issues(referenced_issue)
      IssueLink.new(source: issuable, target: referenced_issue).save
    end

    def linkable_issues(issues)
      issues.select { |issue| can?(current_user, :admin_issue_link, issue) }
    end
  end
end
