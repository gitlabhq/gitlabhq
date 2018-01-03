require_relative 'base_service'

class ValidateNewBranchService < BaseService
  def execute(branch_name)
    valid_branch = Gitlab::GitRefValidator.validate(branch_name)

    unless valid_branch
      return error('Branch name is invalid')
    end

    if project.repository.branch_exists?(branch_name)
      return error('Branch already exists')
    end

    success
  rescue Gitlab::Git::HooksService::PreReceiveError => ex
    error(ex.message)
  end
end
