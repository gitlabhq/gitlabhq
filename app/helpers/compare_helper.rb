module CompareHelper
  def create_mr_button?(from = params[:from], to = params[:to], project = @project)
    from.present? &&
      to.present? &&
      from != to &&
      project.feature_available?(:merge_requests, current_user) &&
      project.repository.branch_names.include?(from) &&
      project.repository.branch_names.include?(to)
  end

  def create_mr_path(from = params[:from], to = params[:to], project = @project)
    new_namespace_project_merge_request_path(
      project.namespace,
      project,
      merge_request: {
        source_branch: to,
        target_branch: from
      }
    )
  end
end
