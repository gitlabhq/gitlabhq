# frozen_string_literal: true

module Emails
  module Notes
    def note_commit_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      @commit = @note.noteable
      @target_url = project_commit_url(*note_target_url_options)
      mail_answer_note_thread(@commit, @note, note_thread_options(reason))
    end

    def note_issue_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      @issue = @note.noteable
      @target_url = Gitlab::UrlBuilder.build(@issue, **note_target_url_query_params)
      mail_answer_note_thread(
        @issue,
        @note,
        note_thread_options(
          reason,
          confidentiality: @issue.confidential?
        )
      )
    end

    def note_merge_request_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      @merge_request = @note.noteable
      @target_url = project_merge_request_url(*note_target_url_options)
      mail_answer_note_thread(@merge_request, @note, note_thread_options(reason))
    end

    def note_snippet_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)
      @snippet = @note.noteable

      case @snippet
      when ProjectSnippet
        @target_url = project_snippet_url(*note_target_url_options)
      when Snippet
        @target_url = gitlab_snippet_url(@note.noteable)
      end

      mail_answer_note_thread(@snippet, @note, note_thread_options(reason))
    end

    def note_design_email(recipient_id, note_id, reason = nil)
      setup_note_mail(note_id, recipient_id)

      design = @note.noteable
      @target_url = ::Gitlab::Routing.url_helpers.designs_project_issue_url(
        @note.resource_parent,
        design.issue,
        note_target_url_query_params.merge(vueroute: design.filename)
      )
      mail_answer_note_thread(design, @note, note_thread_options(reason))
    end

    private

    def note_target_url_options
      [@project || @group, @note.noteable, note_target_url_query_params]
    end

    def note_target_url_query_params
      { anchor: "note_#{@note.id}" }
    end

    def note_thread_options(reason, confidentiality: nil)
      {
        from: sender(@note.author_id),
        to: @recipient.notification_email_for(@project&.group || @group),
        subject: subject("#{@note.noteable.title} (#{@note.noteable.reference_link_text})"),
        'X-GitLab-NotificationReason' => reason
      }.tap do |options|
        options['X-GitLab-ConfidentialIssue'] = confidentiality.to_s unless confidentiality.nil?
      end
    end

    def setup_note_mail(note_id, recipient_id)
      # `note_id` is a `Note` when originating in `NotifyPreview`
      @note = note_id.is_a?(Note) ? note_id : Note.find(note_id)
      @project = @note.project
      @group = @note.noteable.try(:group)
      @group ||= @note.noteable.resource_parent if @note.noteable.try(:resource_parent).is_a?(Group)
      @recipient = User.find(recipient_id)

      if (@project || @group) && @note.persisted?
        @sent_notification = SentNotification.record_note(@note, recipient_id, reply_key)
      end
    end
  end
end

Emails::Notes.prepend_mod_with('Emails::Notes')
