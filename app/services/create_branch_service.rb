require_relative 'base_service'

class CreateBranchService < BaseService
  def execute(branch_name, ref)
    valid_branch = Gitlab::GitRefValidator.validate(branch_name)
    if valid_branch == false
      return error('Branch name invalid')
    end

    repository = project.repository
    existing_branch = repository.find_branch(branch_name)
    if existing_branch
      return error('Branch already exists')
    end

    repository.add_branch(branch_name, ref)
    new_branch = repository.find_branch(branch_name)

    if new_branch
      push_data = build_push_data(project, current_user, new_branch)

      EventCreateService.new.push(project, current_user, push_data)
      project.execute_hooks(push_data.dup, :push_hooks)
      project.execute_services(push_data.dup, :push_hooks)

      success(new_branch)
    else
      error('Invalid reference name')
    end
  end

  def success(branch)
    out = super()
    out[:branch] = branch
    out
  end

  def build_push_data(project, user, branch)
    Gitlab::PushDataBuilder.
      build(project, user, Gitlab::Git::BLANK_SHA, branch.target, "#{Gitlab::Git::BRANCH_REF_PREFIX}#{branch.name}", [])
  end
end
