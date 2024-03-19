# frozen_string_literal: true

module BranchRules
  class DestroyService < BaseService
    private

    def authorized?
      can?(current_user, :destroy_protected_branch, branch_rule)
    end

    def execute_on_branch_rule
      service = ProtectedBranches::DestroyService.new(project, current_user)

      return ServiceResponse.success if service.execute(branch_rule.protected_branch)

      ServiceResponse.error(message: 'Failed to delete branch rule.')
    end
  end
end

BranchRules::DestroyService.prepend_mod
