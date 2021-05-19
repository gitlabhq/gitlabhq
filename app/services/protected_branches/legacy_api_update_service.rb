# frozen_string_literal: true

# The branches#protect API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class LegacyApiUpdateService < BaseService
    attr_reader :protected_branch, :developers_can_push, :developers_can_merge

    def execute(protected_branch)
      @protected_branch = protected_branch
      @developers_can_push = params.delete(:developers_can_push)
      @developers_can_merge = params.delete(:developers_can_merge)

      protected_branch.transaction do
        delete_redundant_access_levels

        case developers_can_push
        when true
          params[:push_access_levels_attributes] = [{ access_level: Gitlab::Access::DEVELOPER }]
        when false
          params[:push_access_levels_attributes] = [{ access_level: Gitlab::Access::MAINTAINER }]
        end

        case developers_can_merge
        when true
          params[:merge_access_levels_attributes] = [{ access_level: Gitlab::Access::DEVELOPER }]
        when false
          params[:merge_access_levels_attributes] = [{ access_level: Gitlab::Access::MAINTAINER }]
        end

        service = ProtectedBranches::UpdateService.new(project, current_user, params)
        service.execute(protected_branch)
      end
    end

    private

    def delete_redundant_access_levels
      unless developers_can_merge.nil?
        protected_branch.merge_access_levels.destroy_all # rubocop: disable Cop/DestroyAll
      end

      unless developers_can_push.nil?
        protected_branch.push_access_levels.destroy_all # rubocop: disable Cop/DestroyAll
      end
    end
  end
end

ProtectedBranches::LegacyApiUpdateService.prepend_mod_with('ProtectedBranches::LegacyApiUpdateService')
