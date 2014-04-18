module CompareHelper
  def compare_to_mr_button?
    @project.merge_requests_enabled &&
      params[:from].present? && 
      params[:to].present? &&
      @repository.branch_names.include?(params[:from]) &&
      @repository.branch_names.include?(params[:to]) &&
      params[:from] != params[:to] &&
      !@refs_are_same
  end

  def compare_mr_path
    new_project_merge_request_path(@project, merge_request: {source_branch: params[:to], target_branch: params[:from]})
  end
end
