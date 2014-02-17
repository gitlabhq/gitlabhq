module Emails
  module Issues
    def new_issue_email(recipient_id, issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      mail(to: recipient(recipient_id),
           subject: subject("#{@issue.title} (##{@issue.iid})"))
    end

    def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id)
      @issue = Issue.find(issue_id)
      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      @project = @issue.project
      mail(to: recipient(recipient_id),
           subject: subject("#{@issue.title} (##{@issue.iid})"))
    end

    def closed_issue_email(recipient_id, issue_id, updated_by_user_id)
      @issue = Issue.find issue_id
      @project = @issue.project
      @updated_by = User.find updated_by_user_id
      mail(to: recipient(recipient_id),
           subject: subject("#{@issue.title} (##{@issue.iid})"))
    end

    def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id)
      @issue = Issue.find issue_id
      @issue_status = status
      @project = @issue.project
      @updated_by = User.find updated_by_user_id
      mail(to: recipient(recipient_id),
           subject: subject("#{@issue.title} (##{@issue.iid})"))
    end
  end
end
