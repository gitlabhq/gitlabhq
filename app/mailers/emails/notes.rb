module Emails
  module Notes
    def note_commit_email(recipient_id, note_id)
      setup_note_mail(note_id, recipient_id)

      @commit = @note.noteable
      @target_url = project_commit_url(*note_target_url_options)
      mail_answer_note_thread(@commit, @note, note_thread_options(recipient_id))
    end

    def note_issue_email(recipient_id, note_id)
      setup_note_mail(note_id, recipient_id)

      @issue = @note.noteable
      @target_url = project_issue_url(*note_target_url_options)
      mail_answer_note_thread(@issue, @note, note_thread_options(recipient_id))
    end

    def note_merge_request_email(recipient_id, note_id)
      setup_note_mail(note_id, recipient_id)

      @merge_request = @note.noteable
      @target_url = project_merge_request_url(*note_target_url_options)
      mail_answer_note_thread(@merge_request, @note, note_thread_options(recipient_id))
    end

    def note_snippet_email(recipient_id, note_id)
      setup_note_mail(note_id, recipient_id)

      @snippet = @note.noteable
      @target_url = project_snippet_url(*note_target_url_options)
      mail_answer_note_thread(@snippet, @note, note_thread_options(recipient_id))
    end

    def note_personal_snippet_email(recipient_id, note_id)
      setup_note_mail(note_id, recipient_id)

      @snippet = @note.noteable
      @target_url = snippet_url(@note.noteable)
      mail_answer_note_thread(@snippet, @note, note_thread_options(recipient_id))
    end

    private

    def note_target_url_options
      [@project, @note.noteable, anchor: "note_#{@note.id}"]
    end

    def note_thread_options(recipient_id)
      {
        from: sender(@note.author_id),
        to: recipient(recipient_id),
        subject: subject("#{@note.noteable.title} (#{@note.noteable.reference_link_text})")
      }
    end

    def setup_note_mail(note_id, recipient_id)
      # `note_id` is a `Note` when originating in `NotifyPreview`
      @note = note_id.is_a?(Note) ? note_id : Note.find(note_id)
      @project = @note.project

      if @project && @note.persisted?
        @sent_notification = SentNotification.record_note(@note, recipient_id, reply_key)
      end
    end
  end
end
