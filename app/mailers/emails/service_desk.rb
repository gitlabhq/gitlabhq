# frozen_string_literal: true

module Emails
  module ServiceDesk
    extend ActiveSupport::Concern
    include MarkupHelper
    include ::ServiceDesk::CustomEmails::Logger

    EMAIL_ATTACHMENTS_SIZE_LIMIT = 10.megabytes.freeze
    VERIFICATION_EMAIL_TIMEOUT = 7

    included do
      override_layout_lookup_table.merge!({
        service_desk_thank_you_email: 'service_desk',
        service_desk_new_note_email: 'service_desk',
        service_desk_new_participant_email: 'service_desk'
      })
    end

    def service_desk_thank_you_email(issue_id)
      setup_service_desk_mail(issue_id)

      email_sender = sender(
        @support_bot.id,
        send_from_user_email: false,
        sender_name: @service_desk_setting&.outgoing_name,
        sender_email: service_desk_sender_email_address
      )

      options = {
        from: email_sender,
        to: @issue.external_author,
        subject: "Re: #{subject_base}",
        **service_desk_template_content_options('thank_you')
      }

      mail_new_thread(@issue, options)
      inject_service_desk_custom_email
    end

    def service_desk_new_note_email(issue_id, note_id, recipient)
      @note = Note.find(note_id)

      setup_service_desk_mail(issue_id, recipient)
      # Prepare uploads for text replacement in markdown content
      setup_service_desk_attachments

      email_sender = sender(
        @note.author_id,
        send_from_user_email: false,
        sender_email: service_desk_sender_email_address
      )

      options = {
        from: email_sender,
        to: recipient.email,
        subject: subject_base,
        **service_desk_template_content_options('new_note')
      }

      mail_answer_thread(@issue, options)
      # Add attachments after email init to guide ActiveMailer
      # to choose the correct multipart content types
      add_uploads_as_attachments
      inject_service_desk_custom_email
    end

    def service_desk_new_participant_email(issue_id, recipient)
      setup_service_desk_mail(issue_id, recipient)

      email_sender = sender(
        @support_bot.id,
        send_from_user_email: false,
        sender_name: @service_desk_setting&.outgoing_name,
        sender_email: service_desk_sender_email_address
      )

      options = {
        from: email_sender,
        to: recipient.email,
        subject: "Re: #{subject_base}",
        **service_desk_template_content_options('new_participant')
      }

      mail_new_thread(@issue, options)
      inject_service_desk_custom_email
    end

    def service_desk_custom_email_verification_email(service_desk_setting)
      @service_desk_setting = service_desk_setting
      @project = @service_desk_setting.project

      email_sender = sender(
        Users::Internal.support_bot.id,
        send_from_user_email: false,
        sender_name: @service_desk_setting.outgoing_name,
        sender_email: @service_desk_setting.custom_email
      )

      @verification_token = @service_desk_setting.custom_email_verification.token

      subject = format(s_("Notify|Verify custom email address %{email} for %{project_name}"),
        email: @service_desk_setting.custom_email,
        project_name: @project.name
      )

      options = {
        from: email_sender,
        to: @service_desk_setting.custom_email_address_for_verification,
        subject: subject
      }
      # Outgoing emails from GitLab usually have this set to true.
      # Service Desk email ingestion ignores auto generated emails.
      headers["Auto-Submitted"] = "no"

      mail_with_locale(options)
      inject_service_desk_custom_email(force: true)
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

    def setup_service_desk_mail(issue_id, issue_email_participant = nil)
      @issue = Issue.find(issue_id)
      @project = @issue.project
      @support_bot = Users::Internal.support_bot

      @service_desk_setting = @project.service_desk_setting

      if issue_email_participant.blank? && @issue.external_author.present?
        issue_email_participant = @issue.issue_email_participants.find_by_email(@issue.external_author)
      end

      @sent_notification = SentNotification.record(@issue, @support_bot.id, reply_key, {
        issue_email_participant: issue_email_participant
      })
    end

    def service_desk_template_content_options(email_type)
      return {} unless template_body = template_content(email_type)

      {
        body: template_body,
        content_type: 'text/html; charset=UTF-8'
      }
    end

    def inject_service_desk_custom_email(force: false)
      return mail if !@service_desk_setting&.custom_email_enabled? && !force
      return mail unless @service_desk_setting.custom_email_credential.present?

      # Only set custom email reply address if it's enabled, not when we force it.
      inject_service_desk_custom_email_reply_address unless force

      log_info(project: @project)

      delivery_options = @service_desk_setting.custom_email_credential.delivery_options
      # We force the use of custom email settings when sending out the verification email.
      # If the credentials aren't correct some servers tend to take a while to answer
      # which leads to some Net::ReadTimeout errors which disguises the
      # real configuration issue.
      # We increase the timeout for verification emails only.
      delivery_options[:read_timeout] = VERIFICATION_EMAIL_TIMEOUT if force

      mail.delivery_method(::Mail::SMTP, delivery_options)
    end

    def inject_service_desk_custom_email_reply_address
      return unless Feature.enabled?(:service_desk_custom_email_reply, @project)

      reply_address = Gitlab::Email::ServiceDesk::CustomEmail.reply_address(@issue, reply_key)
      headers['Reply-To'] = Mail::Address.new(reply_address).tap do |address|
        address.display_name = reply_display_name(@issue)
      end
    end

    def service_desk_sender_email_address
      return unless @service_desk_setting&.custom_email_enabled?

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
        .gsub(/%\{\s*ISSUE_URL\s*\}/, full_issue_url)
    end

    def full_issue_url
      issue_url(@issue)
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
      return '' if @issue.description_html.blank?

      # Remove references etc. from description HTML because external participants
      # are no regular users and don't have permission to access them.
      ::Banzai::Renderer.post_process(@issue.description_html, {})
    end

    def subject_base
      "#{@issue.title} (##{@issue.iid})"
    end

    def setup_service_desk_attachments
      @uploads_to_attach = []
      # Filepaths we should replace in markdown content
      @uploads_as_attachments = []

      uploaders = find_uploaders_for(@note)
      return if uploaders.nil?
      return if uploaders.sum(&:size) > EMAIL_ATTACHMENTS_SIZE_LIMIT

      uploaders.each do |uploader|
        @uploads_to_attach << { filename: uploader.filename, content: uploader.read }
        @uploads_as_attachments << "#{uploader.secret}/#{uploader.filename}"
      rescue StandardError => e
        Gitlab::ErrorTracking.track_exception(e, project_id: @note.project.id)
      end
    end

    def add_uploads_as_attachments
      # We read the uploads before in setup_service_desk_attachments, so let's just add them
      @uploads_to_attach.each do |upload|
        mail.add_file(filename: upload[:filename], content: upload[:content])
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
