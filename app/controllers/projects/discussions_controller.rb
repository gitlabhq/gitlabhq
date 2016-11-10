class Projects::DiscussionsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :merge_request
  before_action :discussion
  before_action :authorize_resolve_discussion!

  def resolve
    discussion.resolve!(current_user)

    MergeRequests::ResolvedDiscussionNotificationService.new(project, current_user).execute(merge_request)

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

  private

  def merge_request
    @merge_request ||= @project.merge_requests.find_by!(iid: params[:merge_request_id])
  end

  def discussion
    @discussion ||= @merge_request.find_diff_discussion(params[:id]) || render_404
  end

  def authorize_resolve_discussion!
    access_denied! unless discussion.can_resolve?(current_user)
  end

  def module_enabled
    render_404 unless @project.feature_available?(:merge_requests, current_user)
  end
end
