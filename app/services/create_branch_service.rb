class CreateBranchService < BaseService
  def execute(branch_name, ref)
    result = ValidateNewBranchService.new(project, current_user)
      .execute(branch_name)

    return result if result[:status] == :error

    new_branch = repository.add_branch(current_user, branch_name, ref)

    if new_branch
      success(new_branch)
    else
      error('Invalid reference name')
    end
  rescue GitHooksService::PreReceiveError => ex
    error(ex.message)
  end

  def success(branch)
    super().merge(branch: branch)
  end
end
