# frozen_string_literal: true

module BranchRules
  class DestroyService < BaseService
    def execute
      raise Gitlab::Access::AccessDeniedError unless can_destroy_branch_rule?

      return destroy_protected_branch if branch_rule.instance_of?(Projects::BranchRule)

      yield if block_given?

      ServiceResponse.error(message: 'Unknown branch rule type.')
    end

    private

    def can_destroy_branch_rule?
      can?(current_user, :destroy_protected_branch, branch_rule)
    end

    def destroy_protected_branch
      service = ProtectedBranches::DestroyService.new(project, current_user)

      return ServiceResponse.success if service.execute(branch_rule.protected_branch)

      ServiceResponse.error(message: 'Failed to delete branch rule.')
    end
  end
end

BranchRules::DestroyService.prepend_mod
