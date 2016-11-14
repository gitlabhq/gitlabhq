require_relative 'base_service'

class CreateBranchService < BaseService
  def execute(branch_name, ref, source_project: @project)
    failure = validate_new_branch(branch_name)

    return failure if failure

    new_branch = if source_project != @project
                   repository.fetch_ref(
                     source_project.repository.path_to_repo,
                     "refs/heads/#{ref}",
                     "refs/heads/#{branch_name}"
                   )

                   repository.after_create_branch

                   repository.find_branch(branch_name)
                 else
                   repository.add_branch(current_user, branch_name, ref)
                 end

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

  private

  def validate_new_branch(branch_name)
    result = ValidateNewBranchService.new(project, current_user).
      execute(branch_name)

    error(result[:message]) if result[:status] == :error
  end
end
