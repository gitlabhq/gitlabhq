# frozen_string_literal: true

module Emails
  module ServiceDesk
    extend ActiveSupport::Concern
    include MarkupHelper

    EMAIL_ATTACHMENTS_SIZE_LIMIT = 10.megabytes.freeze

    included do
      layout 'service_desk', only: [:service_desk_thank_you_email, :service_desk_new_note_email]
    end

    def service_desk_thank_you_email(issue_id)
      setup_service_desk_mail(issue_id)

      email_sender = sender(
        @support_bot.id,
        send_from_user_email: false,
        sender_name: @service_desk_setting&.outgoing_name,
        sender_email: service_desk_sender_email_address
      )
      options = service_desk_options(email_sender, 'thank_you', @issue.external_author)
                  .merge(subject: "Re: #{subject_base}")

      inject_service_desk_custom_email(mail_new_thread(@issue, options))
    end

    def service_desk_new_note_email(issue_id, note_id, recipient)
      @note = Note.find(note_id)
      setup_service_desk_mail(issue_id)

      email_sender = sender(
        @note.author_id,
        send_from_user_email: false,
        sender_email: service_desk_sender_email_address
      )

      add_uploads_as_attachments if Feature.enabled?(:service_desk_new_note_email_native_attachments, @note.project)
      options = service_desk_options(email_sender, 'new_note', recipient)
                  .merge(subject: subject_base)

      inject_service_desk_custom_email(mail_answer_thread(@issue, options))
    end

    private

    def setup_service_desk_mail(issue_id)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @support_bot = User.support_bot

      @service_desk_setting = @project.service_desk_setting

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

    def inject_service_desk_custom_email(mail)
      return mail unless service_desk_custom_email_enabled?

      mail.delivery_method(::Mail::SMTP, @service_desk_setting.custom_email_delivery_options)
    end

    def service_desk_custom_email_enabled?
      Feature.enabled?(:service_desk_custom_email, @project) && @service_desk_setting&.custom_email_enabled?
    end

    def service_desk_sender_email_address
      return unless service_desk_custom_email_enabled?

      @service_desk_setting.custom_email
    end

    def template_content(email_type)
      template = Gitlab::Template::ServiceDeskTemplate.find(email_type, @project)
      text = substitute_template_replacements(template.content)

      context = { project: @project, pipeline: :service_desk_email, uploads_as_attachments: @uploads_as_attachments }

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

    def add_uploads_as_attachments
      uploaders = find_uploaders_for(@note)
      return unless uploaders.present?
      return if uploaders.sum(&:size) > EMAIL_ATTACHMENTS_SIZE_LIMIT

      @uploads_as_attachments = []
      uploaders.each do |uploader|
        attachments[uploader.filename] = uploader.read
        @uploads_as_attachments << "#{uploader.secret}/#{uploader.filename}"
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, project_id: @note.project.id)
      end
    end

    def find_uploaders_for(note)
      uploads = FileUploader::MARKDOWN_PATTERN.scan(note.note)
      return unless uploads.present?

      project = note.project
      uploads.map do |secret, file_name|
        UploaderFinder.new(project, secret, file_name).execute
      end
    rescue StandardError => e
      Gitlab::ErrorTracking.track_exception(e, project_id: note.project.id)
      nil
    end
  end
end
