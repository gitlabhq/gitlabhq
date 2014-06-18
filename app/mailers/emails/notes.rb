module Emails
  module Notes
    def note_commit_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @commit = @note.noteable
      @project = @note.project
      @target_url = project_commit_url(@project, @commit, anchor: "note_#{@note.id}")
      mail(from: sender(@note.author_id),
           to: recipient(recipient_id),
           subject: subject("#{@commit.title} (#{@commit.short_id})"))
    end

    def note_issue_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @issue = @note.noteable
      @project = @note.project
      @target_url = project_issue_url(@project, @issue, anchor: "note_#{@note.id}")
      set_reference("issue_#{@issue.id}")
      mail(from: sender(@note.author_id),
           to: recipient(recipient_id),
           subject: subject("#{@issue.title} (##{@issue.iid})"))
    end

    def note_merge_request_email(recipient_id, note_id)
      @note = Note.find(note_id)
      @merge_request = @note.noteable
      @project = @note.project
      @target_url = project_merge_request_url(@project, @merge_request, anchor: "note_#{@note.id}")
      set_reference("merge_request_#{@merge_request.id}")
      mail(from: sender(@note.author_id),
           to: recipient(recipient_id),
           subject: subject("#{@merge_request.title} (##{@merge_request.iid})"))
    end
  end
end
