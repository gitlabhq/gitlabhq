# frozen_string_literal: true

module Explore
  class CatalogController < Explore::ApplicationController
    feature_category :pipeline_composition
    before_action :check_feature_flag
    before_action :check_resource_access, only: :show

    def show; end

    def index
      render 'show'
    end

    private

    def check_feature_flag
      render_404 unless Feature.enabled?(:global_ci_catalog, current_user)
    end

    def check_resource_access
      render_404 unless catalog_resource.present?
    end

    def catalog_resource
      ::Ci::Catalog::Listing.new(current_user).find_resource(full_path: params[:full_path])
    end
  end
end
