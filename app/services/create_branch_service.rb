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

      # generate push data
      push_data = create_push_data(project, current_user, new_branch)

      # notify composer service
      if project.composer_service && project.composer_service.active
        project.composer_service.async_execute(push_data.dup)
      end

      Event.create_ref_event(project, current_user, new_branch, 'add')
      return success(new_branch)
    else
      return error('Invalid reference name')
    end
  end

  def create_push_data(project, user, branch)
    oldrev = Gitlab::Git::BLANK_SHA
    newrev = branch.target
    ref = 'refs/heads/' + branch.name

    Gitlab::PushDataBuilder.
      build(project, user, oldrev, newrev, ref, [])
  end

  def success(branch)
    out = super()
    out[:branch] = branch
    out
  end
end
