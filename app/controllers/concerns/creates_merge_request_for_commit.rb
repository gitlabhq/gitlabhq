module CreatesMergeRequestForCommit
  extend ActiveSupport::Concern

  def new_merge_request_path
    if @project.forked?
      target_project = @project.forked_from_project || @project
      target_branch = target_project.repository.root_ref
    else
      target_project = @project
      target_branch = @ref
    end

    new_namespace_project_merge_request_path(
      @project.namespace,
      @project,
      merge_request: {
        source_project_id: @project.id,
        target_project_id: target_project.id,
        source_branch: @new_branch,
        target_branch: target_branch
      }
    )
  end

  def create_merge_request?
    params[:create_merge_request] && @new_branch != @ref
  end
end
