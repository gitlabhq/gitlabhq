class Projects::DiscussionsController < Projects::ApplicationController
  include NotesHelper
  include RendersNotes

  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :discussion, only: [:resolve, :unresolve]
  before_action :authorize_resolve_discussion!, only: [:resolve, :unresolve]

  def resolve
    Discussions::ResolveService.new(project, current_user, merge_request: merge_request).execute(discussion)

    render_discussion
  end

  def unresolve
    discussion.unresolve!

    render_discussion
  end

  def show
    render json: {
      truncated_diff_lines: discussion.try(:truncated_diff_lines)
    }
  end

  private

  def render_discussion
    if serialize_notes?
      prepare_notes_for_rendering(discussion.notes, merge_request)
      render_json_with_discussions_serializer
    else
      render_json_with_html
    end
  end

  def render_json_with_discussions_serializer
    render json:
      DiscussionSerializer.new(project: project, noteable: discussion.noteable, current_user: current_user, note_entity:  ProjectNoteEntity)
      .represent(discussion, context: self, render_truncated_diff_lines: true)
  end

  # Legacy method used to render discussions notes when not using Vue on views.
  def render_json_with_html
    render json: {
      resolved_by: discussion.resolved_by.try(:name),
      discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
    }
  end

  def merge_request
    @merge_request ||= MergeRequestsFinder.new(current_user, project_id: @project.id).find_by!(iid: params[:merge_request_id])
  end

  def discussion
    @discussion ||= @merge_request.find_discussion(params[:id]) || render_404
  end

  def authorize_resolve_discussion!
    access_denied! unless discussion.can_resolve?(current_user)
  end
end
