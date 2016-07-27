module ProtectedBranches
  class UpdateService < ProtectedBranches::BaseService
    attr_reader :protected_branch

    def initialize(project, current_user, id, params = {})
      super(project, current_user, params)
      @protected_branch = ProtectedBranch.find(id)
    end

    def execute
      raise Gitlab::Access::AccessDeniedError unless current_user.can?(:admin_project, project)

      ProtectedBranch.transaction do
        set_access_levels!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
