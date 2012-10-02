class NotesController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, only: [:create]

  respond_to :js

  def index
    notes
    respond_with(@notes)
  end

  def create
    @note = Notes::CreateContext.new(project, current_user, params).execute

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
      format.js { render nothing: true }
    end
  end

  def preview
    render text: view_context.markdown(params[:note])
  end

  protected

  def notes
    @notes = Notes::LoadContext.new(project, current_user, params).execute
  end
end
