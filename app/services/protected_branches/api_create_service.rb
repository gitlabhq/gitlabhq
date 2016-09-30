# The protected branches API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class ApiCreateService < BaseService
    def initialize(project, user, params)
      @developers_can_merge = params.delete(:developers_can_merge)
      @developers_can_push = params.delete(:developers_can_push)
      super(project, user, params)
    end

    def execute
      push_access_level =
        if @developers_can_push
          Gitlab::Access::DEVELOPER
        else
          Gitlab::Access::MASTER
        end

      merge_access_level =
        if @developers_can_merge
          Gitlab::Access::DEVELOPER
        else
          Gitlab::Access::MASTER
        end

      @params.merge!(push_access_levels_attributes: [{ access_level: push_access_level }],
                     merge_access_levels_attributes: [{ access_level: merge_access_level }])

      service = ProtectedBranches::CreateService.new(@project, @current_user, @params)
      service.execute
    end
  end
end
