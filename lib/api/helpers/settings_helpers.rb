# frozen_string_literal: true

module API
  module Helpers
    module SettingsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end

      def self.optional_attributes
        [
          *::ApplicationSettingsHelper.visible_attributes,
          *::ApplicationSettingsHelper.external_authorization_service_attributes,
          *::ApplicationSettingsHelper.deprecated_attributes,
          :performance_bar_allowed_group_id,
          # TODO: Once we rename these columns, we can remove them here and add the old
          # names to `ApplicationSettingsHelper.deprecated_attributes` instead.
          # https://gitlab.com/gitlab-org/gitlab/-/issues/340031
          :throttle_unauthenticated_web_enabled,
          :throttle_unauthenticated_web_period_in_seconds,
          :throttle_unauthenticated_web_requests_per_period
        ].freeze
      end
    end
  end
end

API::Helpers::SettingsHelpers.prepend_mod_with('API::Helpers::SettingsHelpers')
