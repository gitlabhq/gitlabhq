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

    def service_desk_custom_email_verification_email(service_desk_setting)
      @service_desk_setting = service_desk_setting

      email_sender = sender(
        User.support_bot.id,
        send_from_user_email: false,
        sender_name: @service_desk_setting.outgoing_name,
        sender_email: @service_desk_setting.custom_email
      )

      @verification_token = @service_desk_setting.custom_email_verification.token

      subject = format(s_("Notify|Verify custom email address %{email} for %{project_name}"),
        email: @service_desk_setting.custom_email,
        project_name: @service_desk_setting.project.name
      )

      options = {
        from: email_sender,
        to: @service_desk_setting.custom_email_address_for_verification,
        subject: subject,
        content_type: "text/plain"
      }
      # Outgoing emails from GitLab usually have this set to true.
      # Service Desk email ingestion ignores auto generated emails.
      headers["Auto-Submitted"] = "no"

      inject_service_desk_custom_email(mail_with_locale(options), force: true)
    end

    def service_desk_verification_triggered_email(service_desk_setting, recipient)
      @service_desk_setting = service_desk_setting
      @triggerer = @service_desk_setting.custom_email_verification.triggerer
      @smtp_address = @service_desk_setting.custom_email_credential.smtp_address

      subject = format(s_("Notify|Verification for custom email %{email} for %{project_name} triggered"),
        email: @service_desk_setting.custom_email,
        project_name: @service_desk_setting.project.name
      )

      email_with_layout(to: recipient, subject: subject)
    end

    def service_desk_verification_result_email(service_desk_setting, recipient)
      @service_desk_setting = service_desk_setting
      @verification = @service_desk_setting.custom_email_verification

      subject = format(s_("Notify|Verification result for custom email %{email} for %{project_name}"),
        email: @service_desk_setting.custom_email,
        project_name: @service_desk_setting.project.name
      )

      email_with_layout(to: recipient, subject: subject)
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
        options[:content_type] = 'text/html' unless attachments.present?
      end
    end

    def inject_service_desk_custom_email(mail, force: false)
      return mail if !service_desk_custom_email_enabled? && !force
      return mail unless @service_desk_setting.custom_email_credential.present?

      mail.delivery_method(::Mail::SMTP, @service_desk_setting.custom_email_credential.delivery_options)
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
        .gsub(/%\{\s*ISSUE_DESCRIPTION\s*\}/, issue_description)
        .gsub(/%\{\s*SYSTEM_HEADER\s*\}/, text_header_message.to_s)
        .gsub(/%\{\s*SYSTEM_FOOTER\s*\}/, text_footer_message.to_s)
        .gsub(/%\{\s*UNSUBSCRIBE_URL\s*\}/, unsubscribe_sent_notification_url(@sent_notification))
        .gsub(/%\{\s*ADDITIONAL_TEXT\s*\}/, service_desk_email_additional_text.to_s)
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

    def issue_description
      @issue.description_html.to_s
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
