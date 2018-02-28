class CreateBranchService < BaseService
  def execute(branch_name, ref)
    create_master_branch if project.empty_repo?

    result = ValidateNewBranchService.new(project, current_user)
      .execute(branch_name)

    return result if result[:status] == :error

    new_branch = repository.add_branch(current_user, branch_name, ref)

    if new_branch
      success(new_branch)
    else
      error('Invalid reference name')
    end
  rescue Gitlab::Git::HooksService::PreReceiveError => ex
    error(ex.message)
  end

  def success(branch)
    super().merge(branch: branch)
  end

  private

  def create_master_branch
    project.repository.create_file(
      current_user,
      '/README.md',
      '',
      message: 'Add README.md',
      branch_name: 'master'
    )
  end
end
