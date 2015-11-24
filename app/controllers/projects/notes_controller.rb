class Projects::NotesController < Projects::ApplicationController
  # Authorize
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_admin_note!, only: [:update, :destroy]
  before_action :find_current_user_notes, except: [:destroy, :delete_attachment, :award_toggle]

  def index
    current_fetched_at = Time.now.to_i

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
      format.html { redirect_back_or_default }
    end
  end

  def update
    @note = Notes::UpdateService.new(project, current_user, note_params).execute(note)

    respond_to do |format|
      format.json { render_note_json(@note) }
      format.html { redirect_back_or_default }
    end
  end

  def destroy
    if note.editable?
      note.destroy
      note.reset_events_cache
    end

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

  def award_toggle
    noteable = if note_params[:noteable_type] == "issue"
                 project.issues.find(note_params[:noteable_id])
               else
                 project.merge_requests.find(note_params[:noteable_id])
               end

    data = {
      author: current_user,
      is_award: true,
      note: note_params[:note].gsub(":", '')
    }

    note = noteable.notes.find_by(data)

    if note
      note.destroy
    else
      Notes::CreateService.new(project, current_user, note_params).execute
    end

    render json: { ok: true }
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
    if params[:view] == 'parallel'
      template = "projects/notes/_diff_notes_with_reply_parallel"
      locals =
        if params[:line_type] == 'old'
          { notes_left: [note], notes_right: [] }
        else
          { notes_left: [], notes_right: [note] }
       end
    else
      template = "projects/notes/_diff_notes_with_reply"
      locals = { notes: [note] }
    end

    render_to_string(
      template,
      layout: false,
      formats: [:html],
      locals: locals
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
      award: note.is_award,
      emoji_path: note.is_award ? view_context.image_url(::AwardEmoji.path_to_emoji_image(note.note)) : "",
      note: note.note,
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

  private

  def find_current_user_notes
    @notes = NotesFinder.new.execute(project, current_user, params)
  end
end
