class Projects::DiscussionsController < Projects::ApplicationController
  before_action :module_enabled
  before_action :merge_request
  before_action :discussion
  before_action :authorize_resolve_discussion!

  def resolve
    return render_404 unless discussion.resolvable?

    discussion.resolve!(current_user)

    head :ok
  end

  def unresolve
    return render_404 unless discussion.resolvable?

    discussion.unresolve!

    head :ok
  end

  private

  def merge_request
    @merge_request ||= @project.merge_requests.find_by!(iid: params[:merge_request_id])
  end

  def discussion
    @discussion ||= @merge_request.discussions.find { |d| d.id == params[:id] } || render_404
  end

  def authorize_resolve_discussion!
    access_denied! unless discussion.can_resolve?(current_user)
  end

  def module_enabled
    render_404 unless @project.merge_requests_enabled
  end
end
