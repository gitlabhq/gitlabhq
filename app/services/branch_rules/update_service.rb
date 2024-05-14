# frozen_string_literal: true

module BranchRules
  class UpdateService < BaseService
    private

    def authorized?
      can?(current_user, :update_branch_rule, branch_rule)
    end

    def execute_on_branch_rule
      protected_branch = ProtectedBranches::UpdateService
        .new(project, current_user, update_params)
        .execute(branch_rule.protected_branch, skip_authorization: true)

      return ServiceResponse.success unless protected_branch.errors.any?

      ServiceResponse.error(message: protected_branch.errors.full_messages)
    end

    def update_params
      transformed_params = params.dup

      extract_branch_protection_params!(transformed_params)
      extract_push_access_levels_params!(transformed_params)
      extract_merge_access_levels_params!(transformed_params)

      transformed_params
    end

    def extract_branch_protection_params!(transformed_params)
      branch_protection_params = transformed_params.delete(:branch_protection)
      return unless branch_protection_params

      transformed_params.merge!(branch_protection_params)
    end

    def extract_push_access_levels_params!(transformed_params)
      push_levels_params = transformed_params.delete(:push_access_levels)
      return unless push_levels_params

      push_levels = branch_rule.branch_protection.push_access_levels
      transformed_params[:push_access_levels_attributes] = access_levels_attributes(push_levels, push_levels_params)
    end

    def extract_merge_access_levels_params!(transformed_params)
      merge_levels_params = transformed_params.delete(:merge_access_levels)
      return unless merge_levels_params

      merge_levels = branch_rule.branch_protection.merge_access_levels
      transformed_params[:merge_access_levels_attributes] = access_levels_attributes(merge_levels, merge_levels_params)
    end

    # In ProtectedBranch we are using:
    #
    #   `accepts_nested_attributes_for :{type}_access_levels, allow_destroy: true`
    #
    # This branch rule update service acts like we have defined this
    # `accepts_nested_attributes_for` with `update: true`.
    #
    # Unfortunately we are unable to modify the `accepts_nested_attributes_for`
    # config as we use this logic in other locations. As we are reusing the
    # ProtectedBranches::UpdateService we also can't custom write the logic to
    # persist the access levels manually.
    #
    # For now the best solution appears to be matching the params against the
    # existing levels to check which access levels still exist and marking
    # unmatched access levels for destruction.
    #
    # Given the following:
    #   access_levels = [{ id: 1, access_level: 30 }, { id: 2, user_id: 1 }, { id: 3, group_id: 1 }]
    #   access_levels_params = [{ access_level: 30 }, { user_id: 1 }, { deploy_key_id: 1 }]
    #
    # The output should be:
    #   [{ id: 3, _destroy: true }, { deploy_key_id: 1 }]
    #
    # NOTE: :user_id and :group_id are only available in EE.
    #
    def access_levels_attributes(access_levels, access_levels_params)
      attributes = access_levels.filter_map do |access_level|
        next if remove_matched_access_level_params!(access_levels_params, access_level)

        # access levels that do not have matching params are marked for deletion
        { id: access_level.id, _destroy: true }
      end

      # concat the remaining access_levels_params that don't match any existing
      # access_levels
      attributes.concat(access_levels_params)
    end

    def remove_matched_access_level_params!(access_levels_params, access_level)
      # <AccessLevel(1) access_level: 0> matches params { access_level: 0 }
      # <AccessLevel(2) deploy_key_id: 1> matched params { deploy_key_id: 1 }
      # NOTE: In EE we also match against :user_id and :group_id
      #
      # If an access_level exists for a passed param we don't need to update it
      # so we can safely reject the params.
      access_levels_params.reject! do |params|
        if access_level.role?
          params[:access_level] == access_level.access_level
        else
          foreign_key = :"#{access_level.type}_id"
          params[foreign_key] == access_level.public_send(foreign_key) # rubocop:disable GitlabSecurity/PublicSend -- "#{access_level.type}_id" is used to fetch the correct foreign_key attribute.
        end
      end
    end

    def permitted_params
      [
        :name,
        {
          branch_protection: [
            :allow_force_push,
            {
              push_access_levels: %i[access_level deploy_key_id],
              merge_access_levels: %i[access_level]
            }
          ]
        }
      ]
    end
  end
end

BranchRules::UpdateService.prepend_mod
