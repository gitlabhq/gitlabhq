class Projects::DiscussionsController < Projects::ApplicationController
  include NotesHelper
  include RendersNotes

  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :discussion
  before_action :authorize_resolve_discussion!

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
      discussion_html: view_to_html_string('discussions/_diff_with_notes', discussion: discussion, expanded: true)
    }
  end

  private

  def render_discussion
    if serialize_notes?
      # TODO - It is not needed to serialize notes when resolving
      # or unresolving discussions. We should remove this behavior
      # passing a parameter to DiscussionEntity to return an empty array
      # for notes.
      # Check issue: https://gitlab.com/gitlab-org/gitlab-ce/issues/42853
      prepare_notes_for_rendering(discussion.notes, merge_request)
      render_json_with_discussions_serializer
    else
      render_json_with_html
    end
  end

  def render_json_with_discussions_serializer
    render json:
      DiscussionSerializer.new(project: project, noteable: discussion.noteable, current_user: current_user, note_entity:  ProjectNoteEntity)
      .represent(discussion, context: self)
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
