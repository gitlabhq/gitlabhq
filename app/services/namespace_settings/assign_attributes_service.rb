# frozen_string_literal: true

module NamespaceSettings
  class AssignAttributesService
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
        param_key: :seat_control,
        user_policy: :change_seat_control
      )
      validate_settings_param_for_root_group(
        param_key: :new_user_signups_cap,
        user_policy: :change_new_user_signups_cap
      )
      validate_settings_param_for_admin(
        param_key: :default_branch_protection,
        user_policy: :update_default_branch_protection
      )
      validate_settings_param_for_admin(
        param_key: :default_branch_protection_defaults,
        user_policy: :update_default_branch_protection
      )
      validate_settings_param_for_root_group(
        param_key: :enabled_git_access_protocol,
        user_policy: :update_git_access_protocol
      )

      handle_default_branch_name
      handle_default_branch_protection unless settings_params[:default_branch_protection].blank?
      handle_early_access_program_participation

      if group.namespace_settings
        group.namespace_settings.attributes = settings_params
      else
        group.build_namespace_settings(settings_params)
      end
    end

    private

    def handle_default_branch_name
      default_branch_key = :default_branch_name

      return if settings_params[default_branch_key].blank?

      unless Gitlab::GitRefValidator.validate(settings_params[default_branch_key])
        settings_params.delete(default_branch_key)
        group.namespace_settings.errors.add(default_branch_key, _('is invalid.'))
      end
    end

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

    def handle_early_access_program_participation
      want_participate = Gitlab::Utils.to_boolean(settings_params[:early_access_program_participant])
      return unless want_participate

      not_participant = !group.namespace_settings&.early_access_program_participant
      settings_params[:early_access_program_joined_by_id] = current_user.id if not_participant
    end

    def validate_resource_access_token_creation_allowed_param
      validate_settings_param_for_admin(
        param_key: :resource_access_token_creation_allowed,
        user_policy: :admin_group
      )
    end

    def validate_settings_param_for_admin(param_key:, user_policy:)
      return if settings_params[param_key].nil?

      unless can?(current_user, user_policy, group)
        settings_params.delete(param_key)
        group.namespace_settings.errors.add(param_key, _('can only be changed by a group admin.'))
      end
    end

    def validate_settings_param_for_root_group(param_key:, user_policy:)
      return if settings_params[param_key].nil?

      validate_settings_param_for_admin(param_key: param_key, user_policy: user_policy)

      unless group.root?
        settings_params.delete(param_key)
        group.namespace_settings.errors.add(param_key, _('only available on top-level groups.'))
      end
    end
  end
end

NamespaceSettings::AssignAttributesService.prepend_mod_with('NamespaceSettings::AssignAttributesService')
