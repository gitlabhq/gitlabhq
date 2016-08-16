require_relative 'base_service'

class DeleteBranchService < BaseService
  def execute(branch_name)
    repository = project.repository
    branch = repository.find_branch(branch_name)

    unless branch
      return error('No such branch', 404)
    end

    if branch_name == repository.root_ref
      return error('Cannot remove HEAD branch', 405)
    end

    if project.protected_branch?(branch_name)
      return error('Protected branch cant be removed', 405)
    end

    unless current_user.can?(:push_code, project)
      return error('You dont have push access to repo', 405)
    end

    if repository.rm_branch(current_user, branch_name)
      success('Branch was removed')
    else
      error('Failed to remove branch')
    end
  rescue GitHooksService::PreReceiveError => ex
    error(ex.message)
  end

  def error(message, return_code = 400)
    super(message).merge(return_code: return_code)
  end

  def success(message)
    super().merge(message: message)
  end

  def build_push_data(branch)
    Gitlab::PushDataBuilder
      .build(project, current_user, branch.target.sha, Gitlab::Git::BLANK_SHA, "#{Gitlab::Git::BRANCH_REF_PREFIX}#{branch.name}", [])
  end
end
