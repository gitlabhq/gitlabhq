class Admin::MailerController < ApplicationController
  layout "admin"
  before_filter :authenticate_user!
  before_filter :authenticate_admin!

  def preview

  end

  def preview_note
    @note = Note.first
    @user = @note.author
    @project = @note.project
    case params[:type]
    when "Commit" then
      @commit = @project.commit
      render :file => 'notify/note_commit_email', :layout => 'notify'
    when "Issue" then
      @issue = Issue.first
      render :file => 'notify/note_issue_email', :layout => 'notify'
    else
      render :file => 'notify/note_wall_email', :layout => 'notify'
    end
  rescue
    render :text => "Preview not available"
  end

  def preview_user_new
    @user = User.first
    @password = "DHasJKDHAS!"

    render :file => 'notify/new_user_email', :layout => 'notify'
  rescue
    render :text => "Preview not available"
  end

  def preview_issue_new
    @issue = Issue.first
    @user = @issue.assignee
    @project = @issue.project
    render :file => 'notify/new_issue_email', :layout => 'notify'
  rescue
    render :text => "Preview not available"
  end
end
