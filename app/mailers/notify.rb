class Notify < ActionMailer::Base
  include Emails::Issues
  include Emails::MergeRequests
  include Emails::Notes
  include Emails::Projects

  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper
  add_template_helper MergeRequestsHelper

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port if Gitlab.config.gitlab_on_non_standard_port?
  default_url_options[:script_name] = Gitlab.config.gitlab.relative_url_root

  default from: Gitlab.config.gitlab.email_from

  # Just send email with 3 seconds delay
  def self.delay
    delay_for(2.seconds)
  end

  def new_user_email(user_id, password)
    @user = User.find(user_id)
    @password = password
    mail(to: @user.email, subject: subject("Account was created for you"))
  end

  def new_ssh_key_email(key_id)
    @key = Key.find(key_id)
    @user = @key.user
    mail(to: @user.email, subject: subject("SSH key was added to your account"))
  end

  private

  # Look up a User by their ID and return their email address
  #
  # recipient_id - User ID
  #
  # Returns a String containing the User's email address.
  def recipient(recipient_id)
    if recipient = User.find(recipient_id)
      recipient.email
    end
  end

  # Formats arguments into a String suitable for use as an email subject
  #
  # extra - Extra Strings to be inserted into the subject
  #
  # Examples
  #
  #   >> subject('Lorem ipsum')
  #   => "GitLab | Lorem ipsum"
  #
  #   # Automatically inserts Project name when @project is set
  #   >> @project = Project.last
  #   => #<Project id: 1, name: "Ruby on Rails", path: "ruby_on_rails", ...>
  #   >> subject('Lorem ipsum')
  #   => "GitLab | Ruby on Rails | Lorem ipsum "
  #
  #   # Accepts multiple arguments
  #   >> subject('Lorem ipsum', 'Dolor sit amet')
  #   => "GitLab | Lorem ipsum | Dolor sit amet"
  def subject(*extra)
    subject = "GitLab"
    subject << (@project ? " | #{@project.name_with_namespace}" : "")
    subject << " | " + extra.join(' | ') if extra.present?
    subject
  end
end
