module ProtectedBranches
  class CreateService < BaseService
    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || authorized?

      protected_branch.save
      protected_branch
    end

    def authorized?
      can?(current_user, :create_protected_branch, protected_branch)
    end

    private

    def protected_branch
      @protected_branch ||= project.protected_branches.new(params)
    end
  end
end
