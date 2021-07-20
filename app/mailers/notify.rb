# frozen_string_literal: true

class Notify < ApplicationMailer
  include ActionDispatch::Routing::PolymorphicRoutes
  include GitlabRoutingHelper
  include EmailsHelper
  include ReminderEmailsHelper
  include IssuablesHelper

  include Emails::Issues
  include Emails::MergeRequests
  include Emails::Notes
  include Emails::PagesDomains
  include Emails::Projects
  include Emails::Profile
  include Emails::Pipelines
  include Emails::Members
  include Emails::AutoDevops
  include Emails::RemoteMirrors
  include Emails::Releases
  include Emails::Groups
  include Emails::Reviews
  include Emails::ServiceDesk
  include Emails::InProductMarketing
  include Emails::AdminNotification

  helper TimeboxesHelper
  helper MergeRequestsHelper
  helper DiffHelper
  helper BlobHelper
  helper EmailsHelper
  helper ReminderEmailsHelper
  helper MembersHelper
  helper AvatarsHelper
  helper GitlabRoutingHelper
  helper IssuablesHelper
  helper InProductMarketingHelper

  def test_email(recipient_email, subject, body)
    mail(to: recipient_email,
         subject: subject,
         body: body.html_safe,
         content_type: 'text/html'
        )
  end

  # Splits "gitlab.corp.company.com" up into "gitlab.corp.company.com",
  # "corp.company.com" and "company.com".
  # Respects set tld length so "company.co.uk" won't match "somethingelse.uk"
  def self.allowed_email_domains
    domain_parts = Gitlab.config.gitlab.host.split(".")
    allowed_domains = []
    begin
      allowed_domains << domain_parts.join(".")
      domain_parts.shift
    end while domain_parts.length > ActionDispatch::Http::URL.tld_length

    allowed_domains
  end

  def can_send_from_user_email?(sender)
    sender_domain = sender.email.split("@").last
    self.class.allowed_email_domains.include?(sender_domain)
  end

  private

  # Return an email address that displays the name of the sender.
  # Only the displayed name changes; the actual email address is always the same.
  def sender(sender_id, send_from_user_email: false, sender_name: nil)
    return unless sender = User.find(sender_id)

    address = default_sender_address
    address.display_name = sender_name.presence || "#{sender.name} (#{sender.to_reference})"

    if send_from_user_email && can_send_from_user_email?(sender)
      address.address = sender.email
    end

    address.format
  end

  # Formats arguments into a String suitable for use as an email subject
  #
  # extra - Extra Strings to be inserted into the subject
  #
  # Examples
  #
  #   >> subject('Lorem ipsum')
  #   => "Lorem ipsum"
  #
  #   # Automatically inserts Project name when @project is set
  #   >> @project = Project.last
  #   => #<Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   >> subject('Lorem ipsum')
  #   => "Ruby on Rails | Lorem ipsum "
  #
  #   # Accepts multiple arguments
  #   >> subject('Lorem ipsum', 'Dolor sit amet')
  #   => "Lorem ipsum | Dolor sit amet"
  def subject(*extra)
    subject = []

    subject << @project.name if @project
    subject << @group.name if @group
    subject.concat(extra) if extra.present?
    subject << Gitlab.config.gitlab.email_subject_suffix if Gitlab.config.gitlab.email_subject_suffix.present?

    subject.join(' | ')
  end

  # Return a string suitable for inclusion in the 'Message-Id' mail header.
  #
  # The message-id is generated from the unique URL to a model object.
  def message_id(model)
    model_name = model.class.model_name.singular_route_key
    "<#{model_name}_#{model.id}@#{Gitlab.config.gitlab.host}>"
  end

  def mail_thread(model, headers = {})
    add_project_headers
    add_unsubscription_headers_and_links
    add_model_headers(model)

    headers['X-GitLab-Reply-Key'] = reply_key

    @reason = headers['X-GitLab-NotificationReason']

    if Gitlab::IncomingEmail.enabled? && @sent_notification
      headers['Reply-To'] = Mail::Address.new(Gitlab::IncomingEmail.reply_address(reply_key)).tap do |address|
        address.display_name = reply_display_name(model)
      end

      fallback_reply_message_id = "<reply-#{reply_key}@#{Gitlab.config.gitlab.host}>"
      headers['References'] ||= []
      headers['References'].unshift(fallback_reply_message_id)

      @reply_by_email = true
    end

    mail(headers)
  end

  # `model` is used on EE code
  def reply_display_name(_model)
    @project.full_name
  end

  # Send an email that starts a new conversation thread,
  # with headers suitable for grouping by thread in email clients.
  #
  # See: mail_answer_thread
  def mail_new_thread(model, headers = {})
    headers['Message-ID'] = message_id(model)

    mail_thread(model, headers)
  end

  # Send an email that responds to an existing conversation thread,
  # with headers suitable for grouping by thread in email clients.
  #
  # For grouping emails by thread, email clients heuristics require the answers to:
  #
  #  * have a subject that begin by 'Re: '
  #  * have a 'In-Reply-To' or 'References' header that references the original 'Message-ID'
  #
  def mail_answer_thread(model, headers = {})
    headers['Message-ID'] = "<#{SecureRandom.hex}@#{Gitlab.config.gitlab.host}>"
    headers['In-Reply-To'] = message_id(model)
    headers['References'] = [message_id(model)]

    headers[:subject] = "Re: #{headers[:subject]}" if headers[:subject]

    mail_thread(model, headers)
  end

  def mail_answer_note_thread(model, note, headers = {})
    headers['Message-ID'] = message_id(note)
    headers['In-Reply-To'] = message_id(note.references.last)
    headers['References'] = note.references.map { |ref| message_id(ref) }

    headers['X-GitLab-Discussion-ID'] = note.discussion.id if note.part_of_discussion? || note.can_be_discussion_note?

    headers[:subject] = "Re: #{headers[:subject]}" if headers[:subject]

    mail_thread(model, headers)
  end

  def reply_key
    @reply_key ||= SentNotification.reply_key
  end

  # This method applies threading headers to the email to identify
  # the instance we are discussing.
  #
  # All model instances must have `#id`, and may implement `#iid`.
  def add_model_headers(object)
    # Use replacement so we don't strip the module.
    prefix = "X-GitLab-#{object.class.name.gsub(/::/, '-')}"

    headers["#{prefix}-ID"] = object.id
    headers["#{prefix}-IID"] = object.iid if object.respond_to?(:iid)
  end

  def add_project_headers
    return unless @project

    headers['X-GitLab-Project'] = @project.name
    headers['X-GitLab-Project-Id'] = @project.id
    headers['X-GitLab-Project-Path'] = @project.full_path
    headers['List-Id'] = "#{@project.full_path} <#{create_list_id_string(@project)}>"
  end

  def add_unsubscription_headers_and_links
    return unless !@labels_url && @sent_notification && @sent_notification.unsubscribable?

    list_unsubscribe_methods = [unsubscribe_sent_notification_url(@sent_notification, force: true)]
    if Gitlab::IncomingEmail.enabled? && Gitlab::IncomingEmail.supports_wildcard?
      list_unsubscribe_methods << "mailto:#{Gitlab::IncomingEmail.unsubscribe_address(reply_key)}"
    end

    headers['List-Unsubscribe'] = list_unsubscribe_methods.map { |e| "<#{e}>" }.join(',')
    @unsubscribe_url = unsubscribe_sent_notification_url(@sent_notification)
  end
end

Notify.prepend_mod_with('Notify')
