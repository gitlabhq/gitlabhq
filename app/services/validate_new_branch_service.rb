require_relative 'base_service'

class ValidateNewBranchService < BaseService
  def execute(branch_name)
    valid_branch = Gitlab::GitRefValidator.validate(branch_name)

    unless valid_branch
      return error('Branch name is invalid')
    end

    repository = project.repository
    existing_branch = repository.find_branch(branch_name)

    if existing_branch
      return error('Branch already exists')
    end

    success
  rescue GitHooksService::PreReceiveError => ex
    error(ex.message)
  end
end
