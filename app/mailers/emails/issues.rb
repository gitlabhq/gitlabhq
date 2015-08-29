module Emails
  module Issues
    def new_issue_email(recipient_id, issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @target_url = namespace_project_issue_url(@project.namespace, @project, @issue)
      mail_new_thread(@issue,
                      from: sender(@issue.author_id),
                      to: recipient(recipient_id),
                      subject: subject("#{@issue.title} (##{@issue.iid})"))

      SentNotification.record(@issue, recipient_id, reply_key)
    end

    def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id, updated_by_user_id)
      @issue = Issue.find(issue_id)
      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      @project = @issue.project
      @target_url = namespace_project_issue_url(@project.namespace, @project, @issue)
      mail_answer_thread(@issue,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@issue.title} (##{@issue.iid})"))

      SentNotification.record(@issue, recipient_id, reply_key)
    end

    def closed_issue_email(recipient_id, issue_id, updated_by_user_id)
      @issue = Issue.find issue_id
      @project = @issue.project
      @updated_by = User.find updated_by_user_id
      @target_url = namespace_project_issue_url(@project.namespace, @project, @issue)
      mail_answer_thread(@issue,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@issue.title} (##{@issue.iid})"))

      SentNotification.record(@issue, recipient_id, reply_key)
    end

    def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id)
      @issue = Issue.find issue_id
      @issue_status = status
      @project = @issue.project
      @updated_by = User.find updated_by_user_id
      @target_url = namespace_project_issue_url(@project.namespace, @project, @issue)
      mail_answer_thread(@issue,
                         from: sender(updated_by_user_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@issue.title} (##{@issue.iid})"))

      SentNotification.record(@issue, recipient_id, reply_key)
    end
  end
end
