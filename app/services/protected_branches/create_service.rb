module ProtectedBranches
  class CreateService < BaseService
    attr_reader :protected_branch

    def execute(skip_authorization: false)
      unless skip_authorization || can?(current_user, :admin_project, project)
        raise Gitlab::Access::AccessDeniedError
      end

      project.protected_branches.create(params)
    end
  end
end
