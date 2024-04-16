# frozen_string_literal: true

module BranchRules
  class UpdateService < BaseService
    private

    def authorized?
      can?(current_user, :update_branch_rule, branch_rule)
    end

    def execute_on_branch_rule
      protected_branch = ProtectedBranches::UpdateService
        .new(project, current_user, params)
        .execute(branch_rule.protected_branch, skip_authorization: true)

      return ServiceResponse.success unless protected_branch.errors.any?

      ServiceResponse.error(message: protected_branch.errors.full_messages)
    end

    def permitted_params
      [:name]
    end
  end
end

BranchRules::UpdateService.prepend_mod
