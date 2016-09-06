# The protected branches API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class ApiCreateService < BaseService
    def initialize(project, user, params, developers_can_push:, developers_can_merge:)
      super(project, user, params)
      @developers_can_merge = developers_can_merge
      @developers_can_push = developers_can_push
    end

    def execute
      if @developers_can_push
        @params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
      else
        @params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
      end

      if @developers_can_merge
        @params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
      else
        @params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
      end

      service = ProtectedBranches::CreateService.new(@project, @current_user, @params)
      service.execute
    end
  end
end
