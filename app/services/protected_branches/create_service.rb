module ProtectedBranches
  class CreateService < ProtectedBranches::BaseService
    attr_reader :protected_branch

    def execute
      raise Gitlab::Access::AccessDeniedError unless current_user.can?(:admin_project, project)

      ProtectedBranch.transaction do
        @protected_branch = project.protected_branches.new(name: params[:name])
        @protected_branch.save!

        @protected_branch.create_push_access_level!
        @protected_branch.create_merge_access_level!

        set_access_levels!
      end

      true
    rescue ActiveRecord::RecordInvalid
      false
    end
  end
end
