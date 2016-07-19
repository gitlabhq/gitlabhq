class Projects::NotesController < Projects::ApplicationController
  include ToggleAwardEmoji

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
    @note = Notes::CreateService.new(project, current_user, note_params).execute

    if @note.is_a?(Note)
      Banzai::NoteRenderer.render([@note], @project, current_user)
    end

    respond_to do |format|
      format.json { render json: note_json(@note) }
      format.html { redirect_back_or_default }
    end
  end

  def update
    @note = Notes::UpdateService.new(project, current_user, note_params).execute(note)

    if @note.is_a?(Note)
      Banzai::NoteRenderer.render([@note], @project, current_user)
    end

    respond_to do |format|
      format.json { render json: note_json(@note) }
      format.html { redirect_back_or_default }
    end
  end

  def destroy
    if note.editable?
      Notes::DeleteService.new(project, current_user).execute(note)
    end

    respond_to do |format|
      format.js { head :ok }
    end
  end

  def delete_attachment
    note.remove_attachment!
    note.update_attribute(:attachment, nil)

    respond_to do |format|
      format.js { head :ok }
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
    return unless note.diff_note?

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
    return unless note.diff_note?

    render_to_string(
      "projects/notes/_discussion",
      layout: false,
      formats: [:html],
      locals: { discussion_notes: [note] }
    )
  end

  def note_json(note)
    if note.is_a?(AwardEmoji)
      {
        valid:  note.valid?,
        award:  true,
        id:     note.id,
        name:   note.name
      }
    elsif note.valid?
      Banzai::NoteRenderer.render([note], @project, current_user)

      attrs = {
        valid: true,
        id: note.id,
        discussion_id: note.discussion_id,
        html: note_to_html(note),
        award: false,
        note: note.note,
        discussion_html: note_to_discussion_html(note),
        discussion_with_diff_html: note_to_discussion_with_diff_html(note)
      }

      # The discussion_id is used to add the comment to the correct discussion
      # element on the merge request page. Among other things, the discussion_id
      # contains the sha of head commit of the merge request.
      # When new commits are pushed into the merge request after the initial
      # load of the merge request page, the discussion elements will still have
      # the old discussion_ids, with the old head commit sha. The new comment,
      # however, will have the new discussion_id with the new commit sha.
      # To ensure that these new comments will still end up in the correct
      # discussion element, we also send the original discussion_id, with the
      # old commit sha, along, and fall back on this value when no discussion
      # element with the new discussion_id could be found.
      if note.new_diff_note? && note.position != note.original_position
        attrs[:original_discussion_id] = note.original_discussion_id
      end

      attrs
    else
      {
        valid: false,
        award: false,
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
      :attachment, :line_code, :commit_id, :type, :position
    )
  end

  def find_current_user_notes
    @notes = NotesFinder.new.execute(project, current_user, params)
  end
end
