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
        # If a protected branch can have only a single access level (CE), delete it to
        # make room for the new access level. If a protected branch can have more than
        # one access level (EE), only remove the relevant access levels. If we don't do this,
        # we'll have a failed validation.
        if protected_branch_restricted_to_single_access_level?
          delete_redundant_ce_access_levels
        else
          delete_redundant_ee_access_levels
        end

        if @developers_can_push
          params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
        elsif @developers_can_push == false
          params.merge!(push_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
        end

        if @developers_can_merge
          params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::DEVELOPER }])
        elsif @developers_can_merge == false
          params.merge!(merge_access_levels_attributes: [{ access_level: Gitlab::Access::MASTER }])
        end

        service = ProtectedBranches::UpdateService.new(@project, @current_user, @params)
        service.execute(protected_branch)
      end
    end

    private

    def delete_redundant_ce_access_levels
      if @developers_can_merge || @developers_can_merge == false
        @protected_branch.merge_access_levels.destroy_all
      end

      if @developers_can_push || @developers_can_push == false
        @protected_branch.push_access_levels.destroy_all
      end
    end

    def delete_redundant_ee_access_levels
      if @developers_can_merge
        @protected_branch.merge_access_levels.developer.destroy_all
      elsif @developers_can_merge == false
        @protected_branch.merge_access_levels.developer.destroy_all
        @protected_branch.merge_access_levels.master.destroy_all
      end

      if @developers_can_push
        @protected_branch.push_access_levels.developer.destroy_all
      elsif @developers_can_push == false
        @protected_branch.push_access_levels.developer.destroy_all
        @protected_branch.push_access_levels.master.destroy_all
      end
    end

    def protected_branch_restricted_to_single_access_level?
      length_validator = ProtectedBranch.validators_on(:push_access_levels).find do |validator|
        validator.is_a? ActiveModel::Validations::LengthValidator
      end
      length_validator.options[:is] == 1 if length_validator
    end
  end
end
