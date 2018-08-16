# frozen_string_literal: true

# The branches#protect API still uses the `developers_can_push` and `developers_can_merge`
# flags for backward compatibility, and so performs translation between that format and the
# internal data model (separate access levels). The translation code is non-trivial, and so
# lives in this service.
module ProtectedBranches
  class LegacyApiUpdateService < BaseService
    def execute(protected_branch)
      @developers_can_push = params.delete(:developers_can_push)
      @developers_can_merge = params.delete(:developers_can_merge)

      @protected_branch = protected_branch

      protected_branch.transaction do
        delete_redundant_ee_access_levels

        case @developers_can_push
        when true
          params[:push_access_levels_attributes] = [{ access_level: Gitlab::Access::DEVELOPER }]
        when false
          params[:push_access_levels_attributes] = [{ access_level: Gitlab::Access::MAINTAINER }]
        end

        case @developers_can_merge
        when true
          params[:merge_access_levels_attributes] = [{ access_level: Gitlab::Access::DEVELOPER }]
        when false
          params[:merge_access_levels_attributes] = [{ access_level: Gitlab::Access::MAINTAINER }]
        end

        service = ProtectedBranches::UpdateService.new(@project, @current_user, @params)
        service.execute(protected_branch)
      end
    end

    private

    def delete_redundant_access_levels
      unless @developers_can_merge.nil?
        @protected_branch.merge_access_levels.destroy_all # rubocop: disable DestroyAll
      end

      unless @developers_can_push.nil?
        @protected_branch.push_access_levels.destroy_all # rubocop: disable DestroyAll
      end
    end

    # If a protected branch can have more than one access level (EE), only
    # remove the relevant access levels. If we don't do this, we'll have a
    # failed validation.
    def delete_redundant_ee_access_levels
      case @developers_can_merge
      when true
        @protected_branch.merge_access_levels.developer.destroy_all
      when false
        @protected_branch.merge_access_levels.developer.destroy_all
        @protected_branch.merge_access_levels.maintainer.destroy_all
      end

      case @developers_can_push
      when true
        @protected_branch.push_access_levels.developer.destroy_all
      when false
        @protected_branch.push_access_levels.developer.destroy_all
        @protected_branch.push_access_levels.maintainer.destroy_all
      end
    end
  end
end
