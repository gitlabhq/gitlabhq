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
      expose(:valid_runner_registrars) { |setting, _options| setting.valid_runner_registrars }

      expose(*::ApplicationSettingsHelper.external_authorization_service_attributes)

      # Also expose these columns under their new attribute names.
      #
      # TODO: Once we rename the columns, we have to swap this around and keep supporting the old names until v5.
      # https://gitlab.com/gitlab-org/gitlab/-/issues/340031
      expose :throttle_unauthenticated_enabled, as: :throttle_unauthenticated_web_enabled
      expose :throttle_unauthenticated_period_in_seconds, as: :throttle_unauthenticated_web_period_in_seconds
      expose :throttle_unauthenticated_requests_per_period, as: :throttle_unauthenticated_web_requests_per_period

      # support legacy names, can be removed in v5
      expose :password_authentication_enabled_for_web, as: :password_authentication_enabled
      expose :password_authentication_enabled_for_web, as: :signin_enabled
      expose :allow_local_requests_from_web_hooks_and_services, as: :allow_local_requests_from_hooks_and_services
      expose :asset_proxy_allowlist, as: :asset_proxy_whitelist

      # This field is deprecated and always returns true
      expose(:housekeeping_bitmaps_enabled) { |_settings, _options| true }

      # These fields are deprecated and always returns housekeeping_optimize_repository_period value
      expose(:housekeeping_full_repack_period) { |settings, _options| settings.housekeeping_optimize_repository_period }
      expose(:housekeeping_gc_period) { |settings, _options| settings.housekeeping_optimize_repository_period }
      expose(:housekeeping_incremental_repack_period) { |settings, _options| settings.housekeeping_optimize_repository_period }
    end
  end
end

API::Entities::ApplicationSetting.prepend_mod_with('API::Entities::ApplicationSetting')
