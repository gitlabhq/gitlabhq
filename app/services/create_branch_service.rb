require_relative 'base_service'

class CreateBranchService < BaseService
  def execute(branch_name, ref, source_project: @project)
    valid_branch = Gitlab::GitRefValidator.validate(branch_name)
    if valid_branch == false
      return error('Branch name is invalid')
    end

    repository = project.repository
    existing_branch = repository.find_branch(branch_name)
    if existing_branch
      return error('Branch already exists')
    end

    new_branch = nil
    if source_project != @project
      repository.with_tmp_ref do |tmp_ref|
        repository.fetch_ref(
          source_project.repository.path_to_repo,
          "refs/heads/#{ref}",
          tmp_ref
        )

        new_branch = repository.add_branch(current_user, branch_name, tmp_ref)
      end
    else
      new_branch = repository.add_branch(current_user, branch_name, ref)
    end

    if new_branch
      # GitPushService handles execution of services and hooks for branch pushes
      success(new_branch)
    else
      error('Invalid reference name')
    end
  rescue GitHooksService::PreReceiveError => ex
    error(ex.message)
  end

  def success(branch)
    out = super()
    out[:branch] = branch
    out
  end
end
