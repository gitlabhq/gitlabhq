# frozen_string_literal: true

module ProtectedBranches
  class DestroyService < ProtectedBranches::BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      protected_branch.destroy.tap { refresh_cache }
    end
  end
end

ProtectedBranches::DestroyService.prepend_mod
