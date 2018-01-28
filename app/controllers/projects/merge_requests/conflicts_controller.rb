class Projects::MergeRequests::ConflictsController < Projects::MergeRequests::ApplicationController
  include IssuableActions

  before_action :authorize_can_resolve_conflicts!

  def show
    respond_to do |format|
      format.html do
        labels
      end

      format.json do
        if @conflicts_list.can_be_resolved_in_ui?
          render json: @conflicts_list
        elsif @merge_request.can_be_merged?
          render json: {
            message: 'The merge conflicts for this merge request have already been resolved. Please return to the merge request.',
            type: 'error'
          }
        else
          render json: {
            message: 'The merge conflicts for this merge request cannot be resolved through GitLab. Please try to resolve them locally.',
            type: 'error'
          }
        end
      end
    end
  end

  def conflict_for_path
    return render_404 unless @conflicts_list.can_be_resolved_in_ui?

    file = @conflicts_list.file_for_path(params[:old_path], params[:new_path])

    return render_404 unless file

    render json: file, full_content: true
  end

  def resolve_conflicts
    return render_404 unless @conflicts_list.can_be_resolved_in_ui?

    if @merge_request.can_be_merged?
      render status: :bad_request, json: { message: 'The merge conflicts for this merge request have already been resolved.' }
      return
    end

    begin
      ::MergeRequests::Conflicts::ResolveService
        .new(merge_request)
        .execute(current_user, params)

      flash[:notice] = 'All merge conflicts were resolved. The merge request can now be merged.'

      render json: { redirect_to: project_merge_request_url(@project, @merge_request, resolved_conflicts: true) }
    rescue Gitlab::Git::Conflict::Resolver::ResolutionError => e
      render status: :bad_request, json: { message: e.message }
    end
  end

  def authorize_can_resolve_conflicts!
    @conflicts_list = ::MergeRequests::Conflicts::ListService.new(@merge_request)

    return render_404 unless @conflicts_list.can_be_resolved_by?(current_user)
  end
end
