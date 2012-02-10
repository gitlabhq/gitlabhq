class Notify < ActionMailer::Base
  default_url_options[:host] = EMAIL_OPTS["host"]
  default from: EMAIL_OPTS["from"]

  def new_user_email(user, password)
    @user = user
    @password = password
    mail(:to => @user.email, :subject => "gitlab | Account was created for you")
  end

  def new_issue_email(issue)
    @user = issue.assignee
    @project = issue.project
    @issue = issue

    mail(:to => @user.email, :subject => "gitlab | New Issue was created")
  end

  def note_wall_email(user, note)
    @user = user
    @note = note
    @project = note.project
    mail(:to => @user.email, :subject => "gitlab | #{@note.project.name} ")
  end

  def note_commit_email(user, note)
    @user = user
    @note = note
    @project = note.project
    @commit = @note.target
    mail(:to => @user.email, :subject => "gitlab | note for commit | #{@note.project.name} ")
  end
  
  def note_merge_request_email(user, note)
    @user = user
    @note = note
    @project = note.project
    @merge_request = note.noteable
    mail(:to => @user.email, :subject => "gitlab | note for merge request | #{@note.project.name} ")
  end

  def note_issue_email(user, note)
    @user = user
    @note = note
    @project = note.project
    @issue = note.noteable
    mail(:to => @user.email, :subject => "gitlab | note for issue #{@issue.id} | #{@note.project.name} ")
  end
  
  def new_merge_request_email(merge_request)
    @user = merge_request.assignee
    @merge_request = merge_request
    @project = merge_request.project
    mail(:to => @user.email, :subject => "gitlab | new merge request | #{@merge_request.title} ")
  end
  
  def changed_merge_request_email(user, merge_request)
    @user = user
    @assignee_was ||= User.find(merge_request.assignee_id_was)
    @merge_request = merge_request
    @project = merge_request.project
    mail(:to => @user.email, :subject => "gitlab | merge request changed | #{@merge_request.title} ")
  end
  
  def changed_issue_email(user, issue)
    @user = user
    @assignee_was ||= User.find(issue.assignee_id_was)
    @issue = issue
    @project = issue.project
    mail(:to => @user.email, :subject => "gitlab | changed issue | #{@issue.title} ")
  end
end
