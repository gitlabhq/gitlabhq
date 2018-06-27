module ProtectedBranches
  class UpdateService < BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :update_protected_branch, protected_branch)

      protected_branch.update(params)
      protected_branch
    end
  end
end
