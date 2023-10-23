# frozen_string_literal: true

module Explore
  class CatalogController < Explore::ApplicationController
    feature_category :pipeline_composition
    before_action :check_feature_flag

    def show; end

    def index
      render 'show'
    end

    private

    def check_feature_flag
      render_404 unless Feature.enabled?(:global_ci_catalog)
    end
  end
end
