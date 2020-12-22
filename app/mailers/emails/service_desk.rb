# frozen_string_literal: true

module Emails
  module ServiceDesk
    extend ActiveSupport::Concern
    include MarkupHelper

    included do
      layout 'service_desk', only: [:service_desk_thank_you_email, :service_desk_new_note_email]
    end

    def service_desk_thank_you_email(issue_id)
      setup_service_desk_mail(issue_id)

      email_sender = sender(
        @support_bot.id,
        send_from_user_email: false,
        sender_name: @project.service_desk_setting&.outgoing_name
      )
      options = service_desk_options(email_sender, 'thank_you', @issue.external_author)
                  .merge(subject: "Re: #{subject_base}")

      mail_new_thread(@issue, options)
    end

    def service_desk_new_note_email(issue_id, note_id, recipient)
      @note = Note.find(note_id)
      setup_service_desk_mail(issue_id)

      email_sender = sender(@note.author_id)
      options = service_desk_options(email_sender, 'new_note', recipient)
                  .merge(subject: subject_base)

      mail_answer_thread(@issue, options)
    end

    private

    def setup_service_desk_mail(issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @support_bot = User.support_bot

      @sent_notification = SentNotification.record(@issue, @support_bot.id, reply_key)
    end

    def service_desk_options(email_sender, email_type, recipient)
      {
        from: email_sender,
        to: recipient
      }.tap do |options|
        next unless template_body = template_content(email_type)

        options[:body] = template_body
        options[:content_type] = 'text/html'
      end
    end

    def template_content(email_type)
      template = Gitlab::Template::ServiceDeskTemplate.find(email_type, @project)
      text = substitute_template_replacements(template.content)

      context = { project: @project, pipeline: :email }
      context[:author] = @note.author if email_type == 'new_note'

      markdown(text, context)
    rescue Gitlab::Template::Finders::RepoTemplateFinder::FileNotFoundError
      nil
    end

    def substitute_template_replacements(template_body)
      template_body
        .gsub(/%\{\s*ISSUE_ID\s*\}/, issue_id)
        .gsub(/%\{\s*ISSUE_PATH\s*\}/, issue_path)
        .gsub(/%\{\s*NOTE_TEXT\s*\}/, note_text)
    end

    def issue_id
      "#{Issue.reference_prefix}#{@issue.iid}"
    end

    def issue_path
      @issue.to_reference(full: true)
    end

    def note_text
      @note&.note.to_s
    end

    def subject_base
      "#{@issue.title} (##{@issue.iid})"
    end
  end
end
