class Projects::NotesController < Projects::ApplicationController
  include ToggleAwardEmoji

  # Authorize
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_admin_note!, only: [:update, :destroy]
  before_action :authorize_resolve_note!, only: [:resolve, :unresolve]
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

  def diff_discussion_html(discussion)
    return unless discussion.diff_discussion?

    if params[:view] == 'parallel'
      template = "discussions/_parallel_diff_discussion"
      locals =
        if params[:line_type] == 'old'
          { discussion_left: discussion, discussion_right: nil }
        else
          { discussion_left: nil, discussion_right: discussion }
        end
    else
      template = "discussions/_diff_discussion"
      locals = { discussion: discussion }
    end

    render_to_string(
      template,
      layout: false,
      formats: [:html],
      locals: locals
    )
  end

  def discussion_html(discussion)
    return unless discussion.diff_discussion?

    render_to_string(
      "discussions/_discussion",
      layout: false,
      formats: [:html],
      locals: { discussion: discussion }
    )
  end

  def note_json(note)
    attrs = {
      award: false,
      id: note.id,
      commands_changes: note.commands_changes
    }

    if note.is_a?(AwardEmoji)
      attrs.merge!(
        valid:  note.valid?,
        award:  true,
        name:   note.name
      )
    elsif note.persisted?
      Banzai::NoteRenderer.render([note], @project, current_user)

      attrs.merge!(
        valid: true,
        discussion_id: note.discussion_id,
        html: note_html(note),
        note: note.note
      )

      if note.diff_note?
        discussion = note.to_discussion

        attrs.merge!(
          diff_discussion_html: diff_discussion_html(discussion),
          discussion_html: discussion_html(discussion)
        )

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
      :note, :noteable, :noteable_id, :noteable_type, :project_id,
      :attachment, :line_code, :commit_id, :type, :position
    )
  end

  def find_current_user_notes
    @notes = NotesFinder.new.execute(project, current_user, params)
  end
end
