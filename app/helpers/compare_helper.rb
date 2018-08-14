module CompareHelper
  def create_mr_button?(from = params[:from], to = params[:to], project = @project)
    from.present? &&
      to.present? &&
      from != to &&
      can?(current_user, :create_merge_request_from, project) &&
      project.repository.branch_exists?(from) &&
      project.repository.branch_exists?(to)
  end

  def create_mr_path(from = params[:from], to = params[:to], project = @project)
    project_new_merge_request_path(
      project,
      merge_request: {
        source_branch: to,
        target_branch: from
      }
    )
  end
end
