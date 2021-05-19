# frozen_string_literal: true

module API
  module Helpers
    module SettingsHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      params :optional_params_ee do
      end

      def self.optional_attributes
        [*::ApplicationSettingsHelper.visible_attributes,
         *::ApplicationSettingsHelper.external_authorization_service_attributes,
         *::ApplicationSettingsHelper.deprecated_attributes,
         :performance_bar_allowed_group_id].freeze
      end
    end
  end
end

API::Helpers::SettingsHelpers.prepend_mod_with('API::Helpers::SettingsHelpers')
