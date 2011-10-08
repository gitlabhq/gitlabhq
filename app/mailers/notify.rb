class Notify < ActionMailer::Base
  default_url_options[:host] = "gitlabhq.com"
  default from: "notify@gitlabhq.com"

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
    @commit = @project.repo.commits(note.noteable_id).first
    mail(:to => @user.email, :subject => "gitlab | #{@note.project.name} ")
  end

  def note_issue_email(user, note)
    @user = user
    @note = note
    @project = note.project
    @issue = note.noteable
    mail(:to => @user.email, :subject => "gitlab | #{@note.project.name} ")
  end
end
