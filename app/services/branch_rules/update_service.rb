# frozen_string_literal: true

module BranchRules
  class UpdateService < BaseService
    PERMITTED_PARAMS = %i[name].freeze

    attr_reader :skip_authorization

    def execute(skip_authorization: false)
      @skip_authorization = skip_authorization

      raise Gitlab::Access::AccessDeniedError unless can_update_branch_rule?

      return update_protected_branch if branch_rule.instance_of?(Projects::BranchRule)

      yield if block_given?

      ServiceResponse.error(message: 'Unknown branch rule type.')
    end

    private

    def permitted_params
      PERMITTED_PARAMS
    end

    def can_update_branch_rule?
      return true if skip_authorization

      can?(current_user, :update_protected_branch, branch_rule)
    end

    def update_protected_branch
      service = ProtectedBranches::UpdateService.new(project, current_user, params)

      service_response = service.execute(branch_rule.protected_branch, skip_authorization: skip_authorization)

      return ServiceResponse.success unless service_response.errors.any?

      ServiceResponse.error(message: service_response.errors.full_messages)
    end
  end
end

BranchRules::UpdateService.prepend_mod
