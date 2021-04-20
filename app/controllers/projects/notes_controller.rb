# frozen_string_literal: true

class Projects::NotesController < Projects::ApplicationController
  include RendersNotes
  include NotesActions
  include NotesHelper
  include ToggleAwardEmoji

  before_action :disable_query_limiting, only: [:create, :update]
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_resolve_note!, only: [:resolve, :unresolve]

  feature_category :issue_tracking

  def delete_attachment
    note.remove_attachment!
    note.update_attribute(:attachment, nil)

    respond_to do |format|
      format.js { head :ok }
    end
  end

  def resolve
    return render_404 unless note.resolvable?

    Notes::ResolveService.new(project, current_user).execute(note)

    discussion = note.discussion

    if serialize_notes?
      render_json_with_notes_serializer
    else
      render json: {
        resolved_by: note.resolved_by.try(:name),
        discussion_headline_html: (view_to_html_string('discussions/_headline', discussion: discussion) if discussion)
      }
    end
  end

  def unresolve
    return render_404 unless note.resolvable?

    note.unresolve!

    discussion = note.discussion

    if serialize_notes?
      render_json_with_notes_serializer
    else
      render json: {
        discussion_headline_html: (view_to_html_string('discussions/_headline', discussion: discussion) if discussion)
      }
    end
  end

  private

  def render_json_with_notes_serializer
    prepare_notes_for_rendering([note])

    render json: note_serializer.represent(note, render_truncated_diff_lines: true)
  end

  def note
    @note ||= @project.notes.find(params[:id])
  end

  alias_method :awardable, :note

  def finder_params
    params.merge(project: project, last_fetched_at: last_fetched_at, notes_filter: notes_filter)
  end

  def authorize_admin_note!
    return access_denied! unless can?(current_user, :admin_note, note)
  end

  def authorize_resolve_note!
    return access_denied! unless can?(current_user, :resolve_note, note)
  end

  def authorize_create_note!
    return unless noteable.lockable?

    access_denied! unless can?(current_user, :create_note, noteable)
  end

  def disable_query_limiting
    Gitlab::QueryLimiting.disable!('https://gitlab.com/gitlab-org/gitlab/-/issues/20800')
  end
end
