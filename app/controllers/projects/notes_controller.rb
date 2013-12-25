class Projects::NotesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, only: [:create]

  respond_to :js

  def index
    @notes = Notes::LoadContext.new(project, current_user, params).execute
    @target_type = params[:target_type].camelize
    @target_id = params[:target_id]

    if params[:target_type] == "merge_request"
      @discussions = Note.discussions_from_notes(@notes)
    end

    respond_to do |format|
      format.html { redirect_to :back }
      format.json do
        render json: {
          html: view_to_html_string("projects/notes/_notes")
        }
      end
    end
  end

  def create
    @note = Notes::CreateContext.new(project, current_user, params).execute
    @target_type = params[:target_type].camelize
    @target_id = params[:target_id]

    respond_to do |format|
      format.html {redirect_to :back}
      format.js
    end
  end

  def destroy
    @note = @project.notes.find(params[:id])
    return access_denied! unless can?(current_user, :admin_note, @note)
    @note.destroy
    @note.reset_events_cache

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def update
    @note = @project.notes.find(params[:id])
    return access_denied! unless can?(current_user, :admin_note, @note)

    @note.update_attributes(params[:note])
    @note.reset_events_cache

    respond_to do |format|
      format.js do
        render js: { success: @note.valid?, id: @note.id, note: view_context.markdown(@note.note) }.to_json
      end
      format.html do
        redirect_to :back
      end
    end
  end

  def delete_attachment
    @note = @project.notes.find(params[:id])
    @note.remove_attachment!
    @note.update_attribute(:attachment, nil)

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def preview
    render text: view_context.markdown(params[:note])
  end
end
