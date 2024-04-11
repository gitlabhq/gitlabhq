# frozen_string_literal: true

module Groups
  class CreateService < Groups::BaseService
    VisibilityError = Class.new(StandardError)
    PermissionError = Class.new(StandardError)

    def initialize(user, params = {})
      @current_user = user
      @params = params.dup
      @chat_team = @params.delete(:create_chat_team)
    end

    def execute
      build_group
      after_build_hook

      validate_visibility_level!
      validate_user_permissions!

      @group.name ||= @group.path.dup

      create_chat_team
      create_group

      if @group.persisted?
        after_successful_creation_hook

        ServiceResponse.success(payload: { group: @group })
      else
        ServiceResponse.error(message: 'Group has errors', payload: { group: @group })
      end

    rescue VisibilityError, PermissionError
      ServiceResponse.error(message: 'Group has errors', payload: { group: @group })
    end

    private

    def create_chat_team
      return unless valid_to_create_chat_team?

      response = ::Mattermost::CreateTeamService.new(@group, current_user).execute
      return ServiceResponse.error(message: 'Group has errors', payload: { group: @group }) if @group.errors.any?

      @group.build_chat_team(name: response['name'], team_id: response['id'])
    end

    def build_group
      remove_unallowed_params
      invert_emails_disabled_to_emails_enabled

      set_visibility_level

      @group = Group.new(params.except(*::NamespaceSetting.allowed_namespace_settings_params))

      set_organization

      @group.build_namespace_settings
      handle_namespace_settings
    end

    def create_group
      Gitlab::Database::QueryAnalyzers::PreventCrossDatabaseModification.temporary_ignore_tables_in_transaction(
        %w[routes redirect_routes], url: 'https://gitlab.com/gitlab-org/gitlab/-/issues/424281'
      ) do
        Group.transaction do
          if @group.save
            @group.add_owner(current_user)
            Integration.create_from_active_default_integrations(@group, :group_id)
          end
        end
      end
    end

    def after_build_hook
      inherit_group_shared_runners_settings
    end

    def after_successful_creation_hook
      # overridden in EE
    end

    def remove_unallowed_params
      unless can?(current_user, :create_group_with_default_branch_protection)
        params.delete(:default_branch_protection)
        params.delete(:default_branch_protection_defaults)
      end

      params.delete(:allow_mfa_for_subgroups)
      params.delete(:math_rendering_limits_enabled)
      params.delete(:lock_math_rendering_limits_enabled)
    end

    def valid_to_create_chat_team?
      Gitlab.config.mattermost.enabled && @chat_team && @group.chat_team.nil?
    end

    def validate_user_permissions!
      if @group.subgroup?
        unless can?(current_user, :create_subgroup, @group.parent)
          @group.parent = nil
          @group.errors.add(:parent_id, s_('CreateGroup|You don’t have permission to create a subgroup in this group.'))

          raise PermissionError
        end
      else
        unless can?(current_user, :create_group)
          @group.errors.add(:base, s_('CreateGroup|You don’t have permission to create groups.'))

          raise PermissionError
        end
      end

      return if organization_setting_valid?

      # We are unsetting this here to match behavior of invalid parent_id above and protect against possible
      # committing to the database of a value that isn't allowed.
      @group.organization = nil

      raise PermissionError
    end

    def can_create_group_in_organization?
      return true if can?(current_user, :create_group, @group.organization)

      message = s_("CreateGroup|You don't have permission to create a group in the provided organization.")
      @group.errors.add(:organization_id, message)

      false
    end

    def matches_parent_organization?
      return true if @group.parent_id.blank?
      return true if @group.parent.organization_id == @group.organization_id

      message = s_("CreateGroup|You can't create a group in a different organization than the parent group.")
      @group.errors.add(:organization_id, message)

      false
    end

    def organization_setting_valid?
      # we check for the params presence explicitly since:
      # 1. We have a default organization_id at db level set and organization exists and may not have the entry
      #    in organization_users table to allow authorization. This shouldn't be the case longterm as we
      #    plan on populating organization_users correctly.
      # 2. We shouldn't need to check if this is allowed if the user didn't try to set it themselves. i.e.
      #    provided in the params
      return true if params[:organization_id].blank?
      # There is a chance the organization is still blank(if not default organization), but that is the only case
      # where we should allow this to not actually be a record in the database.
      # Otherwise it isn't valid to set this to a non-existent record id and we'll check that in the lines after
      # this code.
      return true if @group.organization.blank? && Organizations::Organization.default?(params[:organization_id])

      can_create_group_in_organization? && matches_parent_organization?
    end

    def validate_visibility_level!
      return if Gitlab::VisibilityLevel.allowed_for?(current_user, visibility_level)

      deny_visibility_level(@group)

      raise VisibilityError, 'Visibility level not allowed'
    end

    def set_visibility_level
      return if visibility_level.present?

      params[:visibility_level] = Gitlab::CurrentSettings.current_application_settings.default_group_visibility
    end

    def inherit_group_shared_runners_settings
      return unless @group.parent

      @group.shared_runners_enabled = @group.parent.shared_runners_enabled
      @group.allow_descendants_override_disabled_shared_runners = @group.parent.allow_descendants_override_disabled_shared_runners
    end

    def set_organization
      if params[:organization_id]
        nil # nothing to do, already assigned from params
      elsif @group.parent_id
        @group.organization = @group.parent.organization
      # Rely on middleware setting of the organization, but sometimes it won't be set, so we need to guard it here.
      elsif Current.organization
        @group.organization = Current.organization
      end
    end
  end
end

Groups::CreateService.prepend_mod_with('Groups::CreateService')
