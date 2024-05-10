# frozen_string_literal: true

# The branches#protect API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class LegacyApiCreateService < BaseService
    def execute
      push_access_level =
        if params.delete(:developers_can_push)
          Gitlab::Access::DEVELOPER
        else
          Gitlab::Access::MAINTAINER
        end

      merge_access_level =
        if params.delete(:developers_can_merge)
          Gitlab::Access::DEVELOPER
        else
          Gitlab::Access::MAINTAINER
        end

      @params.merge!(push_access_levels_attributes: [{ access_level: push_access_level }],
        merge_access_levels_attributes: [{ access_level: merge_access_level }])

      service = ProtectedBranches::CreateService.new(project_or_group, @current_user, @params)
      service.execute
    end
  end
end
