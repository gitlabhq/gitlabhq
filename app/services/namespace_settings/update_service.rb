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
      if group.namespace_settings
        group.namespace_settings.attributes = settings_params
      else
        group.build_namespace_settings(settings_params)
      end
    end
  end
end

NamespaceSettings::UpdateService.prepend_if_ee('EE::NamespaceSettings::UpdateService')
