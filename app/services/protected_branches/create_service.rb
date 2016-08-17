module ProtectedBranches
  class CreateService < BaseService
    attr_reader :protected_branch

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      project.protected_branches.create(params)
    end
  end
end
