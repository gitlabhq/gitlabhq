class Notify < ActionMailer::Base
  include Resque::Mailer
  add_template_helper ApplicationHelper
  add_template_helper GitlabMarkdownHelper

  default_url_options[:host]     = Gitlab.config.gitlab.host
  default_url_options[:protocol] = Gitlab.config.gitlab.protocol
  default_url_options[:port]     = Gitlab.config.gitlab.port if Gitlab.config.gitlab_on_non_standard_port?

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
  end

  def note_issue_email(recipient_id, note_id)
    @note = Note.find(note_id)
    @issue = @note.noteable
    @project = @note.project
    mail(to: recipient(recipient_id), subject: subject("note for issue ##{@issue.id}"))
  end

  def note_merge_request_email(recipient_id, note_id)
    @note = Note.find(note_id)
    @merge_request = @note.noteable
    @project = @note.project
    mail(to: recipient(recipient_id), subject: subject("note for merge request !#{@merge_request.id}"))
  end

  def note_wall_email(recipient_id, note_id)
    @note = Note.find(note_id)
    @project = @note.project
    mail(to: recipient(recipient_id), subject: subject)
  end


  #
  # Project
  #

  def project_access_granted_email(user_project_id)
    @users_project = UsersProject.find user_project_id
    @project = @users_project.project
    mail(to: @users_project.user.email,
         subject: subject("access to project was granted"))
  end


  def project_was_moved_email(user_project_id)
    @users_project = UsersProject.find user_project_id
    @project = @users_project.project
    mail(to: @users_project.user.email,
         subject: subject("project was moved"))
  end

  #
  # User
  #

  def new_user_email(user_id, password)
    @user = User.find(user_id)
    @password = password
    mail(to: @user.email, subject: subject("Account was created for you"))
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
  #   => "GitLab | Lorem ipsum | Ruby on Rails"
  #
  #   # Accepts multiple arguments
  #   >> subject('Lorem ipsum', 'Dolor sit amet')
  #   => "GitLab | Lorem ipsum | Dolor sit amet"
  def subject(*extra)
    "GitLab | " << extra.join(' | ') << (@project ? " | #{@project.name}" : "")
  end
end
