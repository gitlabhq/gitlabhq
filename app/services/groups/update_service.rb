# frozen_string_literal: true

module Groups
  class UpdateService < Groups::BaseService
    include UpdateVisibilityLevel

    SETTINGS_PARAMS = [
      :allow_mfa_for_subgroups,
      :early_access_program_participant
    ].freeze

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
      return false unless valid_path_change?
      return false unless update_shared_runners

      handle_changes
      handle_namespace_settings
      handle_hierarchy_cache_update
      group.assign_attributes(params)

      return false if group.errors.present?

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

    def handle_hierarchy_cache_update
      return unless params.key?(:enable_namespace_descendants_cache)

      enabled = Gitlab::Utils.to_boolean(params.delete(:enable_namespace_descendants_cache))

      return unless Feature.enabled?(:group_hierarchy_optimization, group, type: :beta)

      if enabled
        return if group.namespace_descendants

        params[:namespace_descendants_attributes] = {
          traversal_ids: group.traversal_ids,
          all_project_ids: [],
          self_and_descendant_group_ids: [],
          outdated_at: Time.current
        }
      else
        return unless group.namespace_descendants

        params[:namespace_descendants_attributes] = { id: group.id, _destroy: true }
      end
    end

    def valid_path_change?
      return true unless group.packages_feature_enabled?
      return true if params[:path].blank?
      return true if group.has_parent?
      return true if !group.has_parent? && group.path == params[:path]

      # we have a path change on a root group:
      # check that we don't have any npm package with a scope set to the group path
      npm_packages = ::Packages::GroupPackagesFinder
                       .new(current_user, group, packages_class: ::Packages::Npm::Package, preload_pipelines: false)
                       .execute
                       .with_npm_scope(group.path)

      return true unless npm_packages.exists?

      group.errors.add(:path, s_('GroupSettings|cannot change when group contains projects with NPM packages'))
      false
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
      params.delete(:emails_enabled) unless can?(current_user, :set_emails_disabled, group)
      params.delete(:max_artifacts_size) unless can?(current_user, :update_max_artifacts_size, group)

      unless can?(current_user, :update_default_branch_protection, group)
        params.delete(:default_branch_protection)
        params.delete(:default_branch_protection_defaults)
      end

      unless can?(current_user, :admin_namespace, group)
        params.delete(:math_rendering_limits_enabled)
        params.delete(:lock_math_rendering_limits_enabled)
        params.delete(:allow_runner_registration_token)
      end
    end

    def handle_changes
      handle_settings_update
      handle_crm_settings_update
    end

    def handle_settings_update
      settings_params = params.slice(*allowed_settings_params)
      settings_params.merge!({ default_branch_protection: params[:default_branch_protection] }.compact)
      allowed_settings_params.each { |param| params.delete(param) }

      ::NamespaceSettings::AssignAttributesService.new(current_user, group, settings_params).execute
    end

    def handle_crm_settings_update
      return if params[:crm_enabled].nil? && params[:crm_source_group_id].nil?

      crm_enabled = params.delete(:crm_enabled)
      crm_enabled = true if crm_enabled.nil?
      crm_source_group_id = params.delete(:crm_source_group_id)
      return if group.crm_enabled? == crm_enabled && group.crm_settings&.source_group_id == crm_source_group_id

      if group.crm_settings&.source_group_id != crm_source_group_id && group.has_issues_with_contacts?
        group.errors.add(:base, s_('GroupSettings|Contact source cannot be changed when issues already have contacts assigned from a different source.'))
        return
      end

      crm_settings = group.crm_settings || group.build_crm_settings
      crm_settings.enabled = crm_enabled
      crm_settings.source_group_id = crm_source_group_id.presence
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
