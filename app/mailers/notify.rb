class Notify < ActionMailer::Base
  include Resque::Mailer
  add_template_helper ApplicationHelper

  default_url_options[:host]     = Gitlab.config.web_host
  default_url_options[:protocol] = Gitlab.config.web_protocol
  default_url_options[:port]     = Gitlab.config.web_port if Gitlab.config.web_custom_port?

  default from: Gitlab.config.email_from

  def new_user_email(user_id, password)
    @user = User.find(user_id)
    @password = password
    mail(:to => @user.email, :subject => "gitlab | Account was created for you")
  end

  def new_issue_email(issue_id)
    @issue = Issue.find(issue_id)
    @project = @issue.project
    mail(:to => @issue.assignee_email, :subject => "gitlab | new issue ##{@issue.id} | #{@issue.title} | #{@project.name}")
  end

  def note_wall_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @project = @note.project
    mail(:to => recipient.email, :subject => "gitlab | #{@project.name}")
  end

  def note_commit_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @commit = @note.target
    @commit = CommitDecorator.decorate(@commit)
    @project = @note.project
    mail(:to => recipient.email, :subject => "gitlab | note for commit #{@commit.short_id} | #{@commit.title} | #{@project.name}")
  end

  def note_merge_request_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @merge_request = @note.noteable
    @project = @note.project
    mail(:to => recipient.email, :subject => "gitlab | note for merge request !#{@merge_request.id} | #{@project.name}")
  end

  def note_issue_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @issue = @note.noteable
    @project = @note.project
    mail(:to => recipient.email, :subject => "gitlab | note for issue ##{@issue.id} | #{@project.name}")
  end

  def note_wiki_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @wiki = @note.noteable
    @project = @note.project
    mail(:to => recipient.email, :subject => "gitlab | note for wiki | #{@project.name}")
  end

  def new_merge_request_email(merge_request_id)
    @merge_request = MergeRequest.find(merge_request_id)
    @project = @merge_request.project
    mail(:to => @merge_request.assignee_email, :subject => "gitlab | new merge request !#{@merge_request.id} | #{@merge_request.title} | #{@project.name}")
  end

  def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id)
    recipient = User.find(recipient_id)
    @merge_request = MergeRequest.find(merge_request_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    @project = @merge_request.project
    mail(:to => recipient.email, :subject => "gitlab | changed merge request !#{@merge_request.id} | #{@merge_request.title} | #{@project.name}")
  end

  def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id)
    recipient = User.find(recipient_id)
    @issue = Issue.find(issue_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    @project = @issue.project
    mail(:to => recipient.email, :subject => "gitlab | changed issue ##{@issue.id} | #{@issue.title} | #{@project.name}")
  end
end
