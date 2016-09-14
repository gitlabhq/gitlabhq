# The protected branches API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class ApiUpdateService < BaseService
    def initialize(project, user, params, developers_can_push:, developers_can_merge:)
      super(project, user, params)
      @developers_can_merge = developers_can_merge
      @developers_can_push = developers_can_push
    end

    def execute(protected_branch)
      @protected_branch = protected_branch

      protected_branch.transaction do
        delete_redundant_access_levels

        case @developers_can_push
        when true
          params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
        when false
          params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
        end

        case @developers_can_merge
        when true
          params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
        when false
          params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
        end

        service = ProtectedBranches::UpdateService.new(@project, @current_user, @params)
        service.execute(protected_branch)
      end
    end

    private

    def delete_redundant_access_levels
      if @developers_can_merge || @developers_can_merge == false
        @protected_branch.merge_access_levels.destroy_all
      end

      if @developers_can_push || @developers_can_push == false
        @protected_branch.push_access_levels.destroy_all
      end
    end
  end
end
