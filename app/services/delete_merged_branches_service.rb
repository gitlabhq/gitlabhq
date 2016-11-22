require_relative 'base_service'

class DeleteMergedBranchesService < BaseService
  def async_execute
    DeleteMergedBranchesWorker.perform_async(project.id, current_user.id)
  end

  def execute
    raise Gitlab::Access::AccessDeniedError unless can?(current_user, :push_code, project)

    branches = project.repository.branch_names
    branches = branches.select { |branch| project.repository.merged_to_root_ref?(branch) }

    branches.each do |branch|
      DeleteBranchService.new(project, current_user).execute(branch)
    end
  end
end
