class Projects::DiscussionsController < Projects::ApplicationController
  before_action :check_merge_requests_available!
  before_action :merge_request
  before_action :discussion
  before_action :authorize_resolve_discussion!

  def resolve
    Discussions::ResolveService.new(project, current_user, merge_request: merge_request).execute(discussion)

    render json: {
      resolved_by: discussion.resolved_by.try(:name),
      discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
    }
  end

  def unresolve
    discussion.unresolve!

    render json: {
      discussion_headline_html: view_to_html_string('discussions/_headline', discussion: discussion)
    }
  end

  def show
    render json: {
      discussion_html: view_to_html_string('discussions/_diff_with_notes', discussion: discussion)
    }
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
