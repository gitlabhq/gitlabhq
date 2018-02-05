module Emails
  module MergeRequests
    def new_merge_request_email(recipient_id, merge_request_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_new_thread(@merge_request, merge_request_thread_options(@merge_request.author_id, recipient_id, reason))
    end

    def new_mention_in_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @previous_assignee = User.find_by(id: previous_assignee_id) if previous_assignee_id
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def relabeled_merge_request_email(recipient_id, merge_request_id, label_names, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @label_names = label_names
      @labels_url = project_labels_url(@project)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def closed_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def merged_merge_request_email(recipient_id, merge_request_id, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def merge_request_status_email(recipient_id, merge_request_id, status, updated_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @mr_status = status
      @updated_by = User.find(updated_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(updated_by_user_id, recipient_id, reason))
    end

    def resolved_all_discussions_email(recipient_id, merge_request_id, resolved_by_user_id, reason = nil)
      setup_merge_request_mail(merge_request_id, recipient_id)

      @resolved_by = User.find(resolved_by_user_id)
      mail_answer_thread(@merge_request, merge_request_thread_options(resolved_by_user_id, recipient_id, reason))
    end

    private

    def setup_merge_request_mail(merge_request_id, recipient_id)
      @merge_request = MergeRequest.find(merge_request_id)
      @project = @merge_request.project
      @target_url = project_merge_request_url(@project, @merge_request)

      @sent_notification = SentNotification.record(@merge_request, recipient_id, reply_key)
    end

    def merge_request_thread_options(sender_id, recipient_id, reason = nil)
      {
        from: sender(sender_id),
        to: recipient(recipient_id),
        subject: subject("#{@merge_request.title} (#{@merge_request.to_reference})"),
        'X-GitLab-NotificationReason' => reason
      }
    end
  end
end
