# frozen_string_literal: true

module Import
  class OfflineController < ApplicationController
    before_action :check_feature_flag

    feature_category :importers

    def show; end

    private

    def check_feature_flag
      render_404 if Feature.disabled?(:offline_transfer_ui,
        current_user) || Feature.disabled?(:offline_transfer_exports, current_user)
    end
  end
end
