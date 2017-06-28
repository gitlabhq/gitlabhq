module ProtectedBranches
  class UpdateService < BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      protected_branch.update(params)
      protected_branch
    end
  end
end
