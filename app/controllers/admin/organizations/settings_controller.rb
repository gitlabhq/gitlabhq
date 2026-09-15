# frozen_string_literal: true

module Admin
  module Organizations
    class SettingsController < Admin::Organizations::ApplicationController
      feature_category :organization

      def general; end
    end
  end
end
