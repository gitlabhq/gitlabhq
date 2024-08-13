# frozen_string_literal: true

module ProtectedBranches
  class CreateService < ProtectedBranches::BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      save_protected_branch

      refresh_cache

      protected_branch
    end

    def authorized?
      can?(current_user, :create_protected_branch, protected_branch)
    end

    private

    def save_protected_branch
      protected_branch.save.tap do
        # Refresh all_protected_branches association as it is not automatically updated
        project_or_group.all_protected_branches.reset if project_or_group.is_a?(Project)
      end
    end

    def protected_branch
      @protected_branch ||= project_or_group.protected_branches.new(params)
    end
  end
end

ProtectedBranches::CreateService.prepend_mod
