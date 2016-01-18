module Emails
  module Issues
    def new_issue_email(recipient_id, issue_id)
      setup_issue_mail(issue_id, recipient_id)

      mail_new_thread(@issue, issue_thread_options(@issue.author_id, recipient_id))
    end

    def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id, updated_by_user_id)
      setup_issue_mail(issue_id, recipient_id)

      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id))
    end

    def closed_issue_email(recipient_id, issue_id, updated_by_user_id)
      setup_issue_mail(issue_id, recipient_id)

      @updated_by = User.find updated_by_user_id
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id))
    end

    def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id)
      setup_issue_mail(issue_id, recipient_id)

      @issue_status = status
      @updated_by = User.find updated_by_user_id
      mail_answer_thread(@issue, issue_thread_options(updated_by_user_id, recipient_id))
    end

    private

    def issue_thread_options(sender_id, recipient_id)
      {
        from: sender(sender_id),
        to: recipient(recipient_id),
        subject: subject("#{@issue.title} (##{@issue.iid})")
      }
    end

    def setup_issue_mail(issue_id, recipient_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @target_url = namespace_project_issue_url(@project.namespace, @project, @issue)

      @sent_notification = SentNotification.record(@issue, recipient_id, reply_key)
    end
  end
end
