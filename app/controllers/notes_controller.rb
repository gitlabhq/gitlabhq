class NotesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities

  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, :only => [:create]

  respond_to :js

  def index
    @notes = case params[:target_type]
             when "commit" 
               then project.commit_notes(project.commit((params[:target_id]))).fresh.limit(20)
             when "wall"
               then project.common_notes.order("created_at DESC").fresh.limit(20)
             when "issue"
               then project.issues.find(params[:target_id]).notes.inc_author.order("created_at DESC").limit(20)
             when "merge_request"
               then project.merge_requests.find(params[:target_id]).notes.inc_author.order("created_at DESC").limit(20)
             end

    respond_to do |format|
      format.js { respond_with_notes }
    end
  end

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

  protected 

  def respond_with_notes
    if params[:last_id] && params[:first_id]
      @notes = @notes.where("id >= ?", params[:first_id])
    elsif params[:last_id]
      @notes = @notes.where("id > ?", params[:last_id])
    elsif params[:first_id]
      @notes = @notes.where("id < ?", params[:first_id])
    else
      nil
    end
  end
end
