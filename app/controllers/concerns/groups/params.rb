# frozen_string_literal: true

module Groups
  module Params
    extend ActiveSupport::Concern
    include DefaultBranchProtection

    private

    def group_params
      normalize_default_branch_params!(:group)
      params.require(:group).permit(group_params_attributes)
    end

    def group_params_attributes
      [
        :avatar,
        :description,
        :emails_disabled,
        :emails_enabled,
        :show_diff_preview_in_email,
        :mentions_disabled,
        :lfs_enabled,
        :name,
        :path,
        :public,
        :request_access_enabled,
        :share_with_group_lock,
        :visibility_level,
        :parent_id,
        :create_chat_team,
        :chat_team_name,
        :require_two_factor_authentication,
        :two_factor_grace_period,
        :enabled_git_access_protocol,
        :project_creation_level,
        :subgroup_creation_level,
        :default_branch_protection,
        { default_branch_protection_defaults: [
          :allow_force_push,
          :developer_can_initial_push,
          :code_owner_approval_required,
          {
            allowed_to_merge: [:access_level],
            allowed_to_push: [:access_level]
          }
        ] },
        :default_branch_name,
        :allow_mfa_for_subgroups,
        :resource_access_token_creation_allowed,
        :resource_access_token_notify_inherited,
        :lock_resource_access_token_notify_inherited,
        :prevent_sharing_groups_outside_hierarchy,
        :setup_for_company,
        :jobs_to_be_done,
        :crm_enabled,
        :crm_source_group_id,
        :force_pages_access_control,
        :enable_namespace_descendants_cache
      ] + [group_feature_attributes: group_feature_attributes]
    end

    def group_feature_attributes
      []
    end
  end
end

Groups::Params.prepend_mod
