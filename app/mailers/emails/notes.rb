module Emails
  module Notes
    def note_commit_email(recipient_id, note_id)
      note_mail_with_notification(note_id, recipient_id) do
        @commit = @note.noteable
        @target_url = namespace_project_commit_url(*note_target_url_options)

        mail_answer_thread(@commit,
                           from: sender(@note.author_id),
                           to: recipient(recipient_id),
                           subject: subject("#{@commit.title} (#{@commit.short_id})"))
      end
    end

    def note_issue_email(recipient_id, note_id)
      note_mail_with_notification(note_id, recipient_id) do
        @issue = @note.noteable
        @target_url = namespace_project_issue_url(*note_target_url_options)
        mail_answer_thread(@issue, note_thread_options(recipient_id))
      end
    end

    def note_merge_request_email(recipient_id, note_id)
      note_mail_with_notification(note_id, recipient_id) do
        @merge_request = @note.noteable
        @target_url = namespace_project_merge_request_url(*note_target_url_options)
        mail_answer_thread(@merge_request, note_thread_options(recipient_id))
      end
    end

    private

    def note_target_url_options
      [@project.namespace, @project, @note.noteable, anchor: "note_#{@note.id}"]
    end

    def note_thread_options(recipient_id)
      {
        from: sender(@note.author_id),
        to: recipient(recipient_id),
        subject: subject("#{@note.noteable.title} (##{@note.noteable.iid})")
      }
    end

    def note_mail_with_notification(note_id, recipient_id)
      @note = Note.find(note_id)
      @project = @note.project

      yield

      SentNotification.record_note(@note, recipient_id, reply_key)
    end
  end
end
