class Projects::EditTreeController < Projects::BaseTreeController
  before_filter :require_branch_head
  before_filter :blob
  before_filter :authorize_push!
  before_filter :from_merge_request
  before_filter :after_edit_path

  def show
    @last_commit = Gitlab::Git::Commit.last_for_path(@repository, @ref, @path).sha
  end

  def update
    result = Files::UpdateService.new(@project, current_user, params, @ref, @path).execute

    if result[:status] == :success
      flash[:notice] = "Your changes have been successfully committed"

      if from_merge_request
        from_merge_request.reload_code
      end

      redirect_to after_edit_path
    else
      flash[:alert] = result[:error]
      render :show
    end
  end

  def preview
    @content = params[:content]

    diffy = Diffy::Diff.new(@blob.data, @content, diff: '-U 3',
                            include_diff_info: true)
    @diff = Gitlab::DiffParser.new(diffy.diff.scan(/.*\n/))

    render layout: false
  end

  private

  def blob
    @blob ||= @repository.blob_at(@commit.id, @path)
  end

  def after_edit_path
    @after_edit_path ||=
      if from_merge_request
        diffs_project_merge_request_path(from_merge_request.target_project, from_merge_request) +
          "#file-path-#{hexdigest(@path)}"
      else
        project_blob_path(@project, @id)
      end
  end

  def from_merge_request
    # If blob edit was initiated from merge request page
    @from_merge_request ||= MergeRequest.find_by(id: params[:from_merge_request_id])
  end
end
