class NotesController < ApplicationController
  before_filter :project

  # Authorize
  before_filter :add_project_abilities

  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, :only => [:create]

  respond_to :js

  def index
    notes
    respond_with(@notes)
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

  def notes
    @notes = case params[:target_type]
             when "commit" 
               then project.commit_notes(project.commit((params[:target_id]))).fresh.limit(20)
             when "snippet"
               then  project.snippets.find(params[:target_id]).notes
             when "wall"
               then project.common_notes.order("created_at DESC").fresh.limit(50)
             when "issue"
               then project.issues.find(params[:target_id]).notes.inc_author.order("created_at DESC").limit(20)
             when "merge_request"
               then project.merge_requests.find(params[:target_id]).notes.inc_author.order("created_at DESC").limit(20)
             when "wiki"
               then project.wikis.reverse.map {|w| w.notes.fresh }.flatten[0..20]
             end

    @notes = if params[:last_id]
               @notes.where("id > ?", params[:last_id])
             elsif params[:first_id]
               @notes.where("id < ?", params[:first_id])
             else 
               @notes
             end
  end
end
