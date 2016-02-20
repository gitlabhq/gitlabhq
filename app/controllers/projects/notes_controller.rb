class Projects::NotesController < Projects::ApplicationController
  include ToggleEmojiAward

  # Authorize
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_admin_note!, only: [:update, :destroy]
  before_action :find_current_user_notes, only: [:index]

  def index
    current_fetched_at = Time.now.to_i

    notes_json = { notes: [], last_fetched_at: current_fetched_at }

    @notes.each do |note|
      next if note.cross_reference_not_visible_for?(current_user)

      notes_json[:notes] << note_json(note)
    end

    render json: notes_json
  end

  def create
    @note = Notes::CreateService.new(project, current_user, note_params.merge(create_emoji_awards: true)).execute

    respond_to do |format|
      format.json { render json: note_json(@note) }
      format.html { redirect_back_or_default }
    end
  end

  def update
    @note = Notes::UpdateService.new(project, current_user, note_params).execute(note)

    respond_to do |format|
      format.json { render json: note_json(@note) }
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

  private

  def note
    @note ||= @project.notes.find(params[:id])
  end

  alias_method :awardable, :note

  def note_to_html(note)
    render_to_string(
      "projects/notes/_note",
      layout: false,
      formats: [:html],
      locals: { note: note }
    )
  end

  def note_to_discussion_html(note)
    return unless note.for_diff_line?

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

  def note_json(note)
    if note.persisted?
      {
        valid: true,
        id: note.id,
        discussion_id: note.discussion_id,
        html: note_to_html(note),
        note: note.note,
        discussion_html: note_to_discussion_html(note),
        discussion_with_diff_html: note_to_discussion_with_diff_html(note)
      }
    elsif note.emoji_award?
      emoji_award = note.emoji_award
      {
        valid: emoji_award.valid?,
        award: true,
        id: emoji_award.id,
        name: emoji_award.name
      }
    else
      {
        valid: false,
        errors: note.errors
      }
    end
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

  def find_current_user_notes
    @notes = NotesFinder.new.execute(project, current_user, params)
  end
end
