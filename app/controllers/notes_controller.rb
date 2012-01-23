class NotesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities

  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, :only => [:create]

  respond_to :js

  def create
    @note = @project.notes.new(params[:note])
    @note.author = current_user
    @note.notify = true if params[:notify] == '1'
    @note.notify_author = true if params[:notify_author] == '1'
    @note.save

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

end
