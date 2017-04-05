class Projects::NotesController < Projects::ApplicationController
  include RendersNotes
  include ToggleAwardEmoji

  # Authorize
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_admin_note!, only: [:update, :destroy]
  before_action :authorize_resolve_note!, only: [:resolve, :unresolve]

  def index
    current_fetched_at = Time.now.to_i

    notes_json = { notes: [], last_fetched_at: current_fetched_at }

    @notes = notes_finder.execute.inc_relations_for_view
    @notes = prepare_notes_for_rendering(@notes)

    @notes.each do |note|
      next if note.cross_reference_not_visible_for?(current_user)

      notes_json[:notes] << note_json(note)
    end

    render json: notes_json
  end

  def create
    create_params = note_params.merge(
      merge_request_diff_head_sha: params[:merge_request_diff_head_sha],
      in_reply_to_discussion_id: params[:in_reply_to_discussion_id]
    )
    @note = Notes::CreateService.new(project, current_user, create_params).execute

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
      Notes::DestroyService.new(project, current_user).execute(note)
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

  def resolve
    return render_404 unless note.resolvable?

    note.resolve!(current_user)

    MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(note.noteable)

    discussion = note.discussion

    render json: {
      resolved_by: note.resolved_by.try(:name),
      discussion_headline_html: (view_to_html_string('discussions/_headline', discussion: discussion) if discussion)
    }
  end

  def unresolve
    return render_404 unless note.resolvable?

    note.unresolve!

    discussion = note.discussion

    render json: {
      discussion_headline_html: (view_to_html_string('discussions/_headline', discussion: discussion) if discussion)
    }
  end

  private

  def note
    @note ||= @project.notes.find(params[:id])
  end
  alias_method :awardable, :note

  def note_html(note)
    render_to_string(
      "projects/notes/_note",
      layout: false,
      formats: [:html],
      locals: { note: note }
    )
  end

  def discussion_html(discussion)
    return if discussion.individual_note?

    render_to_string(
      "discussions/_discussion",
      layout: false,
      formats: [:html],
      locals: { discussion: discussion }
    )
  end

  def diff_discussion_html(discussion)
    return unless discussion.diff_discussion?

    if params[:view] == 'parallel'
      template = "discussions/_parallel_diff_discussion"
      locals =
        if params[:line_type] == 'old'
          { discussions_left: [discussion], discussions_right: nil }
        else
          { discussions_left: nil, discussions_right: [discussion] }
        end
    else
      template = "discussions/_diff_discussion"
      locals = { discussions: [discussion] }
    end

    render_to_string(
      template,
      layout: false,
      formats: [:html],
      locals: locals
    )
  end

  def note_json(note)
    attrs = {
      commands_changes: note.commands_changes
    }

    if note.persisted?
      attrs.merge!(
        valid: true,
        id: note.id,
        discussion_id: note.discussion_id(noteable),
        html: note_html(note),
        note: note.note
      )

      discussion = note.to_discussion(noteable)
      unless discussion.individual_note?
        attrs.merge!(
          discussion_resolvable: discussion.resolvable?,

          diff_discussion_html: diff_discussion_html(discussion),
          discussion_html: discussion_html(discussion)
        )
      end
    else
      attrs.merge!(
        valid: false,
        errors: note.errors
      )
    end

    attrs
  end

  def authorize_admin_note!
    return access_denied! unless can?(current_user, :admin_note, note)
  end

  def authorize_resolve_note!
    return access_denied! unless can?(current_user, :resolve_note, note)
  end

  def note_params
    params.require(:note).permit(
      :project_id,
      :noteable_type,
      :noteable_id,
      :commit_id,
      :noteable,
      :type,

      :note,
      :attachment,

      # LegacyDiffNote
      :line_code,

      # DiffNote
      :position
    )
  end

  def notes_finder
    @notes_finder ||= NotesFinder.new(project, current_user, params.merge(last_fetched_at: last_fetched_at))
  end

  def noteable
    @noteable ||= notes_finder.target
  end

  def last_fetched_at
    request.headers['X-Last-Fetched-At']
  end
end
