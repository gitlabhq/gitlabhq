module Emails
  module Issues
    def new_issue_email(issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      mail(to: @issue.assignee_email, subject: subject("new issue ##{@issue.id}", @issue.title))
    end

    def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id)
      @issue = Issue.find(issue_id)
      @previous_assignee ||= User.find(previous_assignee_id)
      @project = @issue.project
      mail(to: recipient(recipient_id), subject: subject("changed issue ##{@issue.id}", @issue.title))
    end

    def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id)
      @issue = Issue.find issue_id
      @issue_status = status
      @project = @issue.project
      @updated_by = User.find updated_by_user_id
      mail(to: recipient(recipient_id),
           subject: subject("changed issue ##{@issue.id}", @issue.title))
    end
  end
end
