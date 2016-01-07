module CreatesCommit
  extend ActiveSupport::Concern

  def create_commit(service, success_path:, failure_path:, failure_view: nil, success_notice: nil)
    set_commit_variables

    commit_params = @commit_params.merge(
      source_project: @project,
      source_branch: @ref,
      target_branch: @target_branch
    )

    result = service.new(@tree_edit_project, current_user, commit_params).execute

    if result[:status] == :success
      flash[:notice] = success_notice || "Your changes have been successfully committed."

      if create_merge_request?
        success_path = new_merge_request_path
        target = different_project? ? "project" : "branch"
        flash[:notice] << " You can now submit a merge request to get this change into the original #{target}."
      end

      respond_to do |format|
        format.html { redirect_to success_path }
        format.json { render json: { message: "success", filePath: success_path } }
      end
    else
      flash[:alert] = result[:message]
      respond_to do |format|
        format.html do
          if failure_view
            render failure_view
          else
            redirect_to failure_path
          end
        end
        format.json { render json: { message: "failed", filePath: failure_path } }
      end
    end
  end

  def authorize_edit_tree!
    return if can?(current_user, :push_code, project)
    return if current_user && current_user.already_forked?(project)

    access_denied!
  end

  private

  def new_merge_request_path
    new_namespace_project_merge_request_path(
      @mr_source_project.namespace,
      @mr_source_project,
      merge_request: {
        source_project_id: @mr_source_project.id,
        target_project_id: @mr_target_project.id,
        source_branch: @mr_source_branch,
        target_branch: @mr_target_branch
      }
    )
  end

  def different_project?
    @mr_source_project != @mr_target_project
  end

  def different_branch?
    @mr_source_branch != @mr_target_branch || different_project?
  end

  def create_merge_request?
    params[:create_merge_request].present? && different_branch?
  end

  def set_commit_variables
    @mr_source_branch = @target_branch

    if can?(current_user, :push_code, @project)
      # Edit file in this project
      @tree_edit_project = @project
      @mr_source_project = @project

      if @project.forked?
        # Merge request from this project to fork origin
        @mr_target_project = @project.forked_from_project
        @mr_target_branch = @mr_target_project.repository.root_ref
      else
        # Merge request to this project
        @mr_target_project = @project
        @mr_target_branch = @ref
      end
    else
      # Edit file in fork
      @tree_edit_project = current_user.fork_of(@project)
      # Merge request from fork to this project
      @mr_source_project = @tree_edit_project
      @mr_target_project = @project
      @mr_target_branch = @mr_target_project.repository.root_ref
    end
  end
end
