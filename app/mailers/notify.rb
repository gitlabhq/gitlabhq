class Notify < ActionMailer::Base
  include Resque::Mailer
  add_template_helper ApplicationHelper

  default_url_options[:host] = EMAIL_OPTS["host"]
  default_url_options[:protocol] = -> { EMAIL_OPTS["protocol"] ? EMAIL_OPTS["protocol"] : "http" }.call

  default from: EMAIL_OPTS["from"]

  def new_user_email(user_id, password)
    @user = User.find(user_id)
    @password = password
    mail(:to => @user.email, :subject => "gitlab | Account was created for you")
  end

  def new_issue_email(issue_id)
    @issue = Issue.find(issue_id)
    mail(:to => @issue.assignee_email, :subject => "gitlab | New Issue was created")
  end

  def note_wall_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    mail(:to => recipient.email, :subject => "gitlab | #{@note.project_name} ")
  end

  def note_commit_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @commit = @note.target
    mail(:to => recipient.email, :subject => "gitlab | note for commit | #{@note.project_name} ")
  end

  def note_merge_request_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @merge_request = @note.noteable
    mail(:to => recipient.email, :subject => "gitlab | note for merge request | #{@note.project_name} ")
  end

  def note_issue_email(recipient_id, note_id)
    recipient = User.find(recipient_id)
    @note = Note.find(note_id)
    @issue = @note.noteable
    mail(:to => recipient.email, :subject => "gitlab | note for issue #{@issue.id} | #{@note.project_name} ")
  end

  def new_merge_request_email(merge_request_id)
    @merge_request = MergeRequest.find(merge_request_id)
    mail(:to => @merge_request.assignee_email, :subject => "gitlab | new merge request | #{@merge_request.title} ")
  end

  def reassigned_merge_request_email(recipient_id, merge_request_id, previous_assignee_id)
    recipient = User.find(recipient_id)
    @merge_request = MergeRequest.find(merge_request_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    mail(:to => recipient.email, :subject => "gitlab | merge request changed | #{@merge_request.title} ")
  end

  def reassigned_issue_email(recipient_id, issue_id, previous_assignee_id)
    recipient = User.find(recipient_id)
    @issue = Issue.find(issue_id)
    @previous_assignee ||= User.find(previous_assignee_id)
    mail(:to => recipient.email, :subject => "gitlab | changed issue | #{@issue.title} ")
  end
end
