# frozen_string_literal: true

module API
  module Entities
    class ApplicationSetting < Grape::Entity
      def self.exposed_attributes
        attributes = ::ApplicationSettingsHelper.visible_attributes
        attributes.delete(:performance_bar_allowed_group_path)
        attributes.delete(:performance_bar_enabled)
        attributes.delete(:allow_local_requests_from_hooks_and_services)

        # let's not expose the secret key in a response
        attributes.delete(:asset_proxy_secret_key)
        attributes.delete(:eks_secret_access_key)

        attributes
      end

      expose :id, :performance_bar_allowed_group_id
      expose(*exposed_attributes)
      expose(:restricted_visibility_levels) do |setting, _options|
        setting.restricted_visibility_levels.map { |level| Gitlab::VisibilityLevel.string_level(level) }
      end
      expose(:default_project_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_project_visibility) }
      expose(:default_snippet_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_snippet_visibility) }
      expose(:default_group_visibility) { |setting, _options| Gitlab::VisibilityLevel.string_level(setting.default_group_visibility) }

      expose(*::ApplicationSettingsHelper.external_authorization_service_attributes)

      # support legacy names, can be removed in v5
      expose :password_authentication_enabled_for_web, as: :password_authentication_enabled
      expose :password_authentication_enabled_for_web, as: :signin_enabled
      expose :allow_local_requests_from_web_hooks_and_services, as: :allow_local_requests_from_hooks_and_services
      expose :asset_proxy_allowlist, as: :asset_proxy_whitelist
    end
  end
end

API::Entities::ApplicationSetting.prepend_mod_with('API::Entities::ApplicationSetting')
