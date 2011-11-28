class NotesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities
  before_filter :authorize_write_note!, :only => [:create]

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

    return access_denied! unless can?(current_user, :admin_note, @note)

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
      when "MergeRequest"
        true # someone should write email notification
      when "Snippet"
        true
      else
        Notify.note_wall_email(u, @note).deliver
      end
    end
  end
end
