class NotesController < ApplicationController
  before_filter :project 

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_write_note!, :only => [:create] 
  before_filter :authorize_admin_note!, :only => [:destroy] 

  respond_to :js

  def create
    @note = @project.notes.new(params[:note])
    @note.author = current_user

    if @note.save
      notify if params[:notify] == '1'
    end


    respond_to do |format|
      format.html {redirect_to :back}
      format.js  
    end
  end

  def destroy
    @note = @project.notes.find(params[:id])
    @note.destroy

    respond_to do |format|
      format.js { render :nothing => true }  
    end
  end

  protected 

  def notify
    @project.users.reject { |u| u.id == current_user.id } .each do |u|
      case @note.noteable_type
      when "Commit" then
        Notify.note_commit_email(u, @note).deliver
      when "Issue" then
        Notify.note_issue_email(u, @note).deliver
      else
        Notify.note_wall_email(u, @note).deliver
      end
    end
  end
end
