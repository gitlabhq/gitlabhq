class Projects::EditTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :blob
  before_filter :authorize_push!

  def show
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha
  end

  def update
    result = Files::UpdateService.new(@project, current_user, params, @ref, @path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"

      # If blob edit was initiated from merge request page
      from_merge_request = MergeRequest.find_by(id: params[:from_merge_request_id])

      if from_merge_request
        from_merge_request.reload_code
        redirect_to diffs_project_merge_request_path(from_merge_request.target_project, from_merge_request)
      else
        redirect_to project_blob_path(@project, @id)
      end
    else
      flash[:alert] = result[:error]
      render :show
    end
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)
  end
end
