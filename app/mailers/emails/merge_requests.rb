module Emails
  module MergeRequests
    def new_merge_request_email(recipient_id, merge_request_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_new_thread(@merge_request, merge_request_thread_options(@merge_request.author_id, recipient_id))
    end

    def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def relabeled_merge_request_email(recipient_id, merge_request_id, label_names, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @label_names = label_names
      @labels_url = namespace_project_labels_url(@project.namespace, @project)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def closed_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def merged_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def merge_request_status_email(recipient_id, merge_request_id, status, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @mr_status = status
      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def add_merge_request_approver_email(recipient_id, merge_request_id, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    def approved_merge_request_email(recipient_id, merge_request_id, updated_by_user_id)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @approved_by_users = @merge_request.approved_by_users.map(&:name)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id))
    end

    private

    def setup_merge_request_mail(merge_request_id, recipient_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @target_url = namespace_project_merge_request_url(@project.namespace, @project, @merge_request)

      @sent_notification = SentNotification.record(@merge_request, recipient_id, reply_key)
    end

    def merge_request_thread_options(sender_id, recipient_id)
      {
        from: sender(sender_id),
        to: recipient(recipient_id),
        subject: subject("#{@merge_request.title} (#{@merge_request.to_reference})")
      }
    end
  end
end
