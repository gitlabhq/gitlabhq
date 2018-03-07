module ProtectedBranches
  class CreateService < BaseService
    attr_reader :protected_branch

    def execute(skip_authorization: false)
      raise Gitlab::Access::AccessDeniedError unless skip_authorization || can?(current_user, :admin_project, project)

      project.protected_branches.create(params)
    end
  end
end
