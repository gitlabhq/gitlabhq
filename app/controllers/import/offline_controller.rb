# frozen_string_literal: true

module Import
  class OfflineController < ApplicationController
    before_action :check_feature_flag
    before_action do
      push_frontend_feature_flag(:offline_transfer_exports, current_user)
      push_frontend_feature_flag(:offline_transfer_imports, current_user)
    end

    feature_category :importers

    def show; end

    private

    def check_feature_flag
      return render_404 if Feature.disabled?(:offline_transfer_ui, current_user)

      render_404 unless Feature.enabled?(:offline_transfer_exports,
        current_user) || Feature.enabled?(:offline_transfer_imports, current_user)
    end
  end
end
