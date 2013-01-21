class NotesController < ProjectResourceController
  # Authorize
  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, only: [:create]

  respond_to :js

  def index
    @notes = Notes::LoadContext.new(project, current_user, params).execute
    @target_type = params[:target_type].camelize
    @target_id = params[:target_id]

    if params[:target_type] == "merge_request"
      @discussions   = discussions_from_notes
    end

    respond_with(@notes)
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

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def preview
    render text: view_context.markdown(params[:note])
  end

  protected

  def discussion_notes_for(note)
    @notes.select do |other_note|
      note.discussion_id == other_note.discussion_id
    end
  end

  def discussions_from_notes
    discussion_ids = []
    discussions = []

    @notes.each do |note|
      next if discussion_ids.include?(note.discussion_id)

      # don't group notes for the main target
      if note_for_main_target?(note)
        discussions << [note]
      else
        discussions << discussion_notes_for(note)
        discussion_ids << note.discussion_id
      end
    end

    discussions
  end

  # Helps to distinguish e.g. commit notes in mr notes list
  def note_for_main_target?(note)
    note.for_wall? ||
      (@target_type.camelize == note.noteable_type && !note.for_diff_line?)
  end
end
