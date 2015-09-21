module Emails
  module Notes
    def note_commit_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @commit = @note.noteable
      @project = @note.project
      @target_url = namespace_project_commit_url(@project.namespace, @project,
                                                 @commit, anchor:
                                                 "note_#{@note.id}")
      mail_answer_thread(@commit,
                         from: sender(@note.author_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@commit.title} (#{@commit.short_id})"))

      SentNotification.record_note(@note, recipient_id, reply_key)
    end

    def note_issue_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @issue = @note.noteable
      @project = @note.project
      @target_url = namespace_project_issue_url(@project.namespace, @project,
                                                @issue, anchor:
                                                "note_#{@note.id}")
      mail_answer_thread(@issue,
                         from: sender(@note.author_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@issue.title} (##{@issue.iid})"))

      SentNotification.record_note(@note, recipient_id, reply_key)
    end

    def note_merge_request_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @merge_request = @note.noteable
      @project = @note.project
      @target_url = namespace_project_merge_request_url(@project.namespace,
                                                        @project,
                                                        @merge_request, anchor:
                                                        "note_#{@note.id}")
      mail_answer_thread(@merge_request,
                         from: sender(@note.author_id),
                         to: recipient(recipient_id),
                         subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))

      SentNotification.record_note(@note, recipient_id, reply_key)
    end
  end
end
