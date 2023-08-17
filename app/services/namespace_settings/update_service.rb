# frozen_string_literal: true

module NamespaceSettings
  class UpdateService
    include ::Gitlab::Allowable

    attr_reader :current_user, :group, :settings_params

    def initialize(current_user, group, settings)
      @current_user = current_user
      @group = group
      @settings_params = settings
    end

    def execute
      validate_resource_access_token_creation_allowed_param

      validate_settings_param_for_root_group(
        param_key: :prevent_sharing_groups_outside_hierarchy,
        user_policy: :change_prevent_sharing_groups_outside_hierarchy
      )
      validate_settings_param_for_root_group(
        param_key: :new_user_signups_cap,
        user_policy: :change_new_user_signups_cap
      )
      validate_settings_param_for_root_group(
        param_key: :default_branch_protection,
        user_policy: :update_default_branch_protection
      )
      validate_settings_param_for_root_group(
        param_key: :default_branch_protection_defaults,
        user_policy: :update_default_branch_protection
      )

      handle_default_branch_protection unless settings_params[:default_branch_protection].blank?

      if group.namespace_settings
        group.namespace_settings.attributes = settings_params
      else
        group.build_namespace_settings(settings_params)
      end
    end

    private

    def handle_default_branch_protection
      # We are migrating default_branch_protection from an integer
      # column to a jsonb column. While completing the rest of the
      # work, we want to start translating the updates sent to the
      # existing column into the json. Eventually, we will be updating
      # the jsonb column directly and deprecating the original update
      # path. Until then, we want to sync up both columns.
      protection = Gitlab::Access::BranchProtection.new(settings_params.delete(:default_branch_protection).to_i)
      settings_params[:default_branch_protection_defaults] = protection.to_hash
    end

    def validate_resource_access_token_creation_allowed_param
      return if settings_params[:resource_access_token_creation_allowed].nil?

      unless can?(current_user, :admin_group, group)
        settings_params.delete(:resource_access_token_creation_allowed)
        group.namespace_settings.errors.add(:resource_access_token_creation_allowed, _('can only be changed by a group admin.'))
      end
    end

    def validate_settings_param_for_root_group(param_key:, user_policy:)
      return if settings_params[param_key].nil?

      unless can?(current_user, user_policy, group)
        settings_params.delete(param_key)
        group.namespace_settings.errors.add(param_key, _('can only be changed by a group admin.'))
      end

      unless group.root?
        settings_params.delete(param_key)
        group.namespace_settings.errors.add(param_key, _('only available on top-level groups.'))
      end
    end
  end
end

NamespaceSettings::UpdateService.prepend_mod_with('NamespaceSettings::UpdateService')
