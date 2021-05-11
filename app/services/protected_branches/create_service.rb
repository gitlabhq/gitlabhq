# frozen_string_literal: true

module ProtectedBranches
  class CreateService < BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      save_protected_branch

      protected_branch
    end

    def authorized?
      can?(current_user, :create_protected_branch, protected_branch)
    end

    private

    def save_protected_branch
      protected_branch.save
    end

    def protected_branch
      @protected_branch ||= project.protected_branches.new(params)
    end
  end
end

ProtectedBranches::CreateService.prepend_mod_with('ProtectedBranches::CreateService')
