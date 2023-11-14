# frozen_string_literal: true

module API
  module Helpers
    module UserPreferencesHelpers
      extend ActiveSupport::Concern
      extend Grape::API::Helpers

      def update_user_namespace_settings(attrs)
        # This method will be redefined in EE.
        attrs
      end
    end
  end
end

API::Helpers::UserPreferencesHelpers.prepend_mod_with('API::Helpers::UserPreferencesHelpers')
