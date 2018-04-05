class Projects::NotesController < Projects::ApplicationController
  include NotesActions
  include NotesHelper
  include ToggleAwardEmoji

  before_action :whitelist_query_limiting, only: [:create]
  before_action :authorize_read_note!
  before_action :authorize_create_note!, only: [:create]
  before_action :authorize_resolve_note!, only: [:resolve, :unresolve]

  #
  # This is a fix to make spinach feature tests passing:
  # Controller actions are returned from AbstractController::Base and methods of parent classes are
  #   excluded in order to return only specific controller related methods.
  # That is ok for the app (no :create method in ancestors)
  #   but fails for tests because there is a :create method on FactoryBot (one of the ancestors)
  #
  # see https://github.com/rails/rails/blob/v4.2.7/actionpack/lib/abstract_controller/base.rb#L78
  #
  def create
    super
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
    Notes::RenderService.new(current_user).execute([note], project)

    render json: note_serializer.represent(note)
  end

  def note
    @note ||= @project.notes.find(params[:id])
  end

  alias_method :awardable, :note

  def finder_params
    params.merge(last_fetched_at: last_fetched_at)
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

  def whitelist_query_limiting
    Gitlab::QueryLimiting.whitelist('https://gitlab.com/gitlab-org/gitlab-ce/issues/42383')
  end
end
