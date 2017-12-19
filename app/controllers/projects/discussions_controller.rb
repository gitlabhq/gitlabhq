class Projects::DiscussionsController < Projects::ApplicationController
  include RendersNotes

  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :discussion
  before_action :authorize_resolve_discussion!

  def resolve
    Discussions::ResolveService.new(project, current_user, merge_request: merge_request).execute(discussion)

    if cookies[:vue_mr_discussions] == 'true'
      prepare_notes_for_rendering(discussion.notes)
      # TODO: We may need to strip when cross_reference_not_visible_for

      render json: DiscussionSerializer.new(project: project, noteable: discussion.noteable, current_user: current_user).represent(discussion)
    else
      render json: {
        resolved_by: discussion.resolved_by.try(:name),
        discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
      }
    end
  end

  def unresolve
    discussion.unresolve!

    if cookies[:vue_mr_discussions] == 'true'
      prepare_notes_for_rendering(discussion.notes)
      # TODO: We may need to strip when cross_reference_not_visible_for
      # TODO: This needs to be refactored to DRY

      render json: DiscussionSerializer.new(project: project, noteable: discussion.noteable, current_user: current_user).represent(discussion)
    else
      render json: {
        discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
      }
    end
  end

  private

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
