require_relative 'base_service'

class ValidateNewBranchService < BaseService
  def execute(branch_name)
    valid_branch = Gitlab::GitRefValidator.validate(branch_name)

    unless valid_branch
      return error('Branch name is invalid',  nil, branch_name)
    end

    if project.repository.branch_exists?(branch_name)
      return error('Branch already exists',  nil, branch_name)
    end

    success
  rescue Gitlab::Git::HooksService::PreReceiveError => ex
    error(ex.message,  nil, branch_name)
  end

  private

  def error(message, http_status = nil, branch_name = nil)
    super(message, http_status).merge(branch_name: branch_name)
  end
end
