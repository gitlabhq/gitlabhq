# frozen_string_literal: true

module ProtectedBranches
  class UpdateService < ProtectedBranches::BaseService
    def execute(protected_branch, skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?(protected_branch)

      old_merge_access_levels = protected_branch.merge_access_levels.map(&:clone)
      old_push_access_levels = protected_branch.push_access_levels.map(&:clone)

      if protected_branch.update(params)
        after_execute(protected_branch: protected_branch, old_merge_access_levels: old_merge_access_levels, old_push_access_levels: old_push_access_levels)

        refresh_cache
      end

      protected_branch
    end

    def authorized?(protected_branch)
      can?(current_user, :update_protected_branch, protected_branch)
    end
  end
end

ProtectedBranches::UpdateService.prepend_mod
