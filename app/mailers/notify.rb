<<<<<<< HEAD
class Notify < BaseMailer
  include ActionDispatch::Routing::PolymorphicRoutes

  include Emails::Issues
  include Emails::MergeRequests
  include Emails::Notes
  include Emails::Projects
  include Emails::Profile
  include Emails::Groups
  include Emails::Builds

  add_template_helper MergeRequestsHelper
  add_template_helper EmailsHelper

  def test_email(recipient_email, subject, body)
    mail(to: recipient_email,
         subject: subject,
         body: body.html_safe,
         content_type: 'text/html'
        )
=======
class Notify < ActionMailer::Base

  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port if Gitlab.config.gitlab_on_non_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  default from: Gitlab.config.gitlab.email_from



  #
  # Issue
  #

  def new_issue_email(issue_id)
    @issue = Issue.find(issue_id)
    @project = @issue.project
    mail(to: @issue.assignee_email, subject: subject("new issue ##{@issue.id}", @issue.title))
  end

  def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id)
    @issue = Issue.find(issue_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    @project = @issue.project
    mail(to: recipient(recipient_id), subject: subject("changed issue ##{@issue.id}", @issue.title))
  end

  def issue_status_changed_email(recipient_id, issue_id, status, updated_by_user_id)
    @issue = Issue.find issue_id
    @issue_status = status
    @project = @issue.project
    @updated_by = User.find updated_by_user_id
    mail(to: recipient(recipient_id),
        subject: subject("changed issue ##{@issue.id}", @issue.title))
  end



  #
  # Merge Request
  #

  def new_merge_request_email(merge_request_id)
    @merge_request = MergeRequest.find(merge_request_id)
    @project = @merge_request.project
    mail(to: @merge_request.assignee_email, subject: subject("new merge request !#{@merge_request.id}", @merge_request.title))
  end

  def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id)
    @merge_request = MergeRequest.find(merge_request_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    @project = @merge_request.project
    mail(to: recipient(recipient_id), subject: subject("changed merge request !#{@merge_request.id}", @merge_request.title))
  end



  #
  # Note
  #

  def note_commit_email(recipient_id, note_id)
    @note = Note.find(note_id)
    @commit = @note.noteable
    @commit = CommitDecorator.decorate(@commit)
    @project = @note.project
    mail(to: recipient(recipient_id), subject: subject("note for commit #{@commit.short_id}", @commit.title))
<<<<<<< HEAD
<<<<<<< HEAD
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> gitlabhq/4-1-stable
=======
>>>>>>> origin/4-1-stable
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
  def sender(sender_id, send_from_user_email = false)
    return unless sender = User.find(sender_id)

    address = default_sender_address
    address.display_name = sender.name

    if send_from_user_email && can_send_from_user_email?(sender)
      address.address = sender.email
    end

    address.format
  end

  # Look up a User by their ID and return their email address
  #
  # recipient_id - User ID
  #
  # Returns a String containing the User's email address.
  def recipient(recipient_id)
    @current_user = User.find(recipient_id)
    @current_user.notification_email
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
    subject = ""
    subject << "#{@project.name} | " if @project
    subject << extra.join(' | ') if extra.present?
    subject
  end

  # Return a string suitable for inclusion in the 'Message-Id' mail header.
  #
  # The message-id is generated from the unique URL to a model object.
  def message_id(model)
    model_name = model.class.model_name.singular_route_key
    "<#{model_name}_#{model.id}@#{Gitlab.config.gitlab.host}>"
  end

  def mail_thread(model, headers = {})
    if @project
      headers['X-GitLab-Project'] = @project.name
      headers['X-GitLab-Project-Id'] = @project.id
      headers['X-GitLab-Project-Path'] = @project.path_with_namespace
    end

    headers["X-GitLab-#{model.class.name}-ID"] = model.id

    if reply_key
      headers['X-GitLab-Reply-Key'] = reply_key

      address = Mail::Address.new(Gitlab::IncomingEmail.reply_address(reply_key))
      address.display_name = @project.name_with_namespace

      headers['Reply-To'] = address

      @reply_by_email = true
    end

    mail(headers)
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
    headers['References'] = message_id(model)

    headers[:subject].prepend('Re: ') if headers[:subject]

    mail_thread(model, headers)
  end

  def reply_key
    @reply_key ||= SentNotification.reply_key
  end
end
