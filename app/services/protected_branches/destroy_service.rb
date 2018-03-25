module ProtectedBranches
  class DestroyService < BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      protected_branch.destroy
    end
  end
end
