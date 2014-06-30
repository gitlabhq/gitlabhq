class Projects::NotesController < Projects::ApplicationController
  # Authorize
  before_filter :authorize_read_note!
  before_filter :authorize_write_note!, only: [:create]
  before_filter :authorize_admin_note!, only: [:update, :destroy]

  def index
    current_fetched_at = Time.now.to_i
    @notes = NotesFinder.new.execute(project, current_user, params)

    notes_json = { notes: [], last_fetched_at: current_fetched_at }

    @notes.each do |note|
      notes_json[:notes] << {
        id: note.id,
        html: note_to_html(note)
      }
    end

    render json: notes_json
  end

  def create
    @note = Notes::CreateService.new(project, current_user, note_params).execute

    respond_to do |format|
      format.json { render_note_json(@note) }
      format.html { redirect_to :back }
    end
  end

  def update
    note.update_attributes(note_params)
    note.reset_events_cache

    respond_to do |format|
      format.json { render_note_json(note) }
      format.html { redirect_to :back }
    end
  end

  def destroy
    note.destroy
    note.reset_events_cache

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def delete_attachment
    note.remove_attachment!
    note.update_attribute(:attachment, nil)

    respond_to do |format|
      format.js { render nothing: true }
    end
  end

  def preview
    render text: view_context.markdown(params[:note])
  end

  private

  def note
    @note ||= @project.notes.find(params[:id])
  end

  def note_to_html(note)
    render_to_string(
      "projects/notes/_note",
      layout: false,
      formats: [:html],
      locals: { note: note }
    )
  end

  def note_to_discussion_html(note)
    render_to_string(
      "projects/notes/_diff_notes_with_reply",
      layout: false,
      formats: [:html],
      locals: { notes: [note] }
    )
  end

  def note_to_discussion_with_diff_html(note)
    return unless note.for_diff_line?

    render_to_string(
      "projects/notes/_discussion",
      layout: false,
      formats: [:html],
      locals: { discussion_notes: [note] }
    )
  end

  def render_note_json(note)
    render json: {
      id: note.id,
      discussion_id: note.discussion_id,
      html: note_to_html(note),
      discussion_html: note_to_discussion_html(note),
      discussion_with_diff_html: note_to_discussion_with_diff_html(note)
    }
  end

  def authorize_admin_note!
    return access_denied! unless can?(current_user, :admin_note, note)
  end

  def note_params
    params.require(:note).permit(
      :note, :noteable, :noteable_id, :noteable_type, :project_id,
      :attachment, :line_code, :commit_id
    )
  end
end
