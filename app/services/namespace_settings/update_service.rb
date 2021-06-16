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
      validate_prevent_sharing_groups_outside_hierarchy_param

      if group.namespace_settings
        group.namespace_settings.attributes = settings_params
      else
        group.build_namespace_settings(settings_params)
      end
    end

    private

    def validate_resource_access_token_creation_allowed_param
      return if settings_params[:resource_access_token_creation_allowed].nil?

      unless can?(current_user, :admin_group, group)
        settings_params.delete(:resource_access_token_creation_allowed)
        group.namespace_settings.errors.add(:resource_access_token_creation_allowed, _('can only be changed by a group admin.'))
      end
    end

    def validate_prevent_sharing_groups_outside_hierarchy_param
      return if settings_params[:prevent_sharing_groups_outside_hierarchy].nil?

      unless can?(current_user, :change_prevent_sharing_groups_outside_hierarchy, group)
        settings_params.delete(:prevent_sharing_groups_outside_hierarchy)
        group.namespace_settings.errors.add(:prevent_sharing_groups_outside_hierarchy, _('can only be changed by a group admin.'))
      end
    end
  end
end

NamespaceSettings::UpdateService.prepend_mod_with('NamespaceSettings::UpdateService')
