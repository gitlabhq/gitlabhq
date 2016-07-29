module ProtectedBranches
  class UpdateService < BaseService
    attr_reader :protected_branch

    def execute(protected_branch)
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      @protected_branch = protected_branch
      @protected_branch.update(params)
      @protected_branch
    end
  end
end
