# frozen_string_literal: true

module Explore
  class AiCatalogController < Explore::ApplicationController
    feature_category :duo_workflow
    before_action :check_feature_flag

    private

    def check_feature_flag
      render_404 unless Feature.enabled?(:global_ai_catalog, current_user)
    end
  end
end
