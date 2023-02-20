# frozen_string_literal: true

module ProtectedBranches
  class DestroyService < ProtectedBranches::BaseService
    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :destroy_protected_branch, protected_branch)

      protected_branch.destroy.tap do
        refresh_cache
        after_execute
      end
    end
  end
end

ProtectedBranches::DestroyService.prepend_mod
