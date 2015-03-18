require_relative 'base_service'

class DeleteBranchService < BaseService
  def execute(branch_name)
    repository = project.repository
    branch = repository.find_branch(branch_name)

    # No such branch
    unless branch
      return error('No such branch', 404)
    end

    if branch_name == repository.root_ref
      return error('Cannot remove HEAD branch', 405)
    end

    # Dont allow remove of protected branch
    if project.protected_branch?(branch_name)
      return error('Protected branch cant be removed', 405)
    end

    # Dont allow user to remove branch if he is not allowed to push
    unless current_user.can?(:push_code, project)
      return error('You dont have push access to repo', 405)
    end

    if repository.rm_branch(branch_name)
      push_data = build_push_data(branch)

      EventCreateService.new.push(project, current_user, push_data)
      project.execute_hooks(push_data.dup, :push_hooks)
      project.execute_services(push_data.dup, :push_hooks)

      success('Branch was removed')
    else
      error('Failed to remove branch')
    end
  end

  def error(message, return_code = 400)
    out = super(message)
    out[:return_code] = return_code
    out
  end

  def success(message)
    out = super()
    out[:message] = message
    out
  end

  def build_push_data(branch)
    Gitlab::PushDataBuilder
      .build(project, current_user, branch.target, Gitlab::Git::BLANK_SHA, "#{Gitlab::Git::BRANCH_REF_PREFIX}#{branch.name}", [])
  end
end
