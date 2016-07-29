module ProtectedBranches
  class CreateService < BaseService
    attr_reader :protected_branch

    def execute
      raise Gitlab::Access::AccessDeniedError unless can?(current_user, :admin_project, project)

      protected_branch = project.protected_branches.new(params)

      ProtectedBranch.transaction do
        protected_branch.save!

        if protected_branch.push_access_level.blank?
          protected_branch.create_push_access_level!(access_level: Gitlab::Access::MASTER)
        end

        if protected_branch.merge_access_level.blank?
          protected_branch.create_merge_access_level!(access_level: Gitlab::Access::MASTER)
        end
      end

      protected_branch
    rescue ActiveRecord::RecordInvalid
      protected_branch
    end
  end
end
