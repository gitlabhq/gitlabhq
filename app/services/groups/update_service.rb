# frozen_string_literal: true

module Groups
  class UpdateService < Groups::BaseService
    include UpdateVisibilityLevel

    SETTINGS_PARAMS = [:allow_mfa_for_subgroups].freeze

    def execute
      reject_parent_id!
      remove_unallowed_params

      before_assignment_hook(group, params)

      if renaming_group_with_container_registry_images?
        group.errors.add(:base, container_images_error)
        return false
      end

      return false unless valid_visibility_level_change?(group, group.visibility_attribute_value(params))

      return false unless valid_share_with_group_lock_change?

      return false unless valid_path_change_with_npm_packages?

      return false unless update_shared_runners

      handle_changes

      handle_namespace_settings

      group.assign_attributes(params)

      begin
        success = group.save

        after_update if success

        success
      rescue Gitlab::UpdatePathError => e
        group.errors.add(:base, e.message)

        false
      end
    end

    private

    def valid_path_change_with_npm_packages?
      return true unless group.packages_feature_enabled?
      return true if params[:path].blank?
      return true if !group.has_parent? && group.path == params[:path]

      npm_packages = ::Packages::GroupPackagesFinder.new(current_user, group, package_type: :npm).execute
      if npm_packages.exists?
        group.errors.add(:path, s_('GroupSettings|cannot change when group contains projects with NPM packages'))
        return
      end

      true
    end

    def before_assignment_hook(group, params)
      @full_path_before = group.full_path
      @path_before = group.path
    end

    def renaming_group_with_container_registry_images?
      renaming? && group.has_container_repository_including_subgroups?
    end

    def renaming?
      new_path = params[:path]

      new_path && new_path != @path_before
    end

    def container_images_error
      s_("GroupSettings|Cannot update the path because there are projects under this group that contain Docker images in their Container Registry. Please remove the images from your projects first and try again.")
    end

    def after_update
      if group.previous_changes.include?(group.visibility_level_field) && group.private?
        # don't enqueue immediately to prevent todos removal in case of a mistake
        TodosDestroyer::GroupPrivateWorker.perform_in(Todo::WAIT_FOR_DELETE, group.id)
      end

      update_two_factor_requirement_for_subgroups

      publish_event
    end

    def update_two_factor_requirement_for_subgroups
      settings = group.namespace_settings
      return if settings.allow_mfa_for_subgroups

      if settings.previous_changes.include?(:allow_mfa_for_subgroups)
        # enque in batches members update
        DisallowTwoFactorForSubgroupsWorker.perform_async(group.id)
      end
    end

    def reject_parent_id!
      params.delete(:parent_id)
    end

    # overridden in EE
    def remove_unallowed_params
      params.delete(:emails_disabled) unless can?(current_user, :set_emails_disabled, group)
      params.delete(:default_branch_protection) unless can?(current_user, :update_default_branch_protection, group)
    end

    def handle_changes
      handle_settings_update
      handle_crm_settings_update unless params[:crm_enabled].nil?
    end

    def handle_settings_update
      settings_params = params.slice(*allowed_settings_params)
      allowed_settings_params.each { |param| params.delete(param) }

      ::NamespaceSettings::UpdateService.new(current_user, group, settings_params).execute
    end

    def handle_crm_settings_update
      crm_enabled = params.delete(:crm_enabled)
      return if group.crm_enabled? == crm_enabled

      crm_settings = group.crm_settings || group.build_crm_settings
      crm_settings.enabled = crm_enabled
      crm_settings.save
    end

    def allowed_settings_params
      SETTINGS_PARAMS
    end

    def valid_share_with_group_lock_change?
      return true unless changing_share_with_group_lock?
      return true if can?(current_user, :change_share_with_group_lock, group)

      group.errors.add(:share_with_group_lock, s_('GroupSettings|cannot be disabled when the parent group "Share with group lock" is enabled, except by the owner of the parent group'))
      false
    end

    def changing_share_with_group_lock?
      return false if params[:share_with_group_lock].nil?

      params[:share_with_group_lock] != group.share_with_group_lock
    end

    def update_shared_runners
      return true if params[:shared_runners_setting].nil?

      result = Groups::UpdateSharedRunnersService.new(group, current_user, shared_runners_setting: params.delete(:shared_runners_setting)).execute

      return true if result[:status] == :success

      group.errors.add(:update_shared_runners, result[:message])
      false
    end

    def publish_event
      return unless renaming?

      event = Groups::GroupPathChangedEvent.new(
        data: {
          group_id: group.id,
          root_namespace_id: group.root_ancestor.id,
          old_path: @full_path_before,
          new_path: group.full_path
        }
      )

      Gitlab::EventStore.publish(event)
    end
  end
end

Groups::UpdateService.prepend_mod_with('Groups::UpdateService')
