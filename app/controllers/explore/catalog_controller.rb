# frozen_string_literal: true

module Explore
  class CatalogController < Explore::ApplicationController
    include ProductAnalyticsTracking

    feature_category :pipeline_composition
    before_action :check_resource_access, only: :show
    track_internal_event :index, name: 'unique_users_visiting_ci_catalog', conditions: :current_user

    def show; end

    def index
      render 'show'
    end

    private

    def check_resource_access
      render_404 unless catalog_resource.present?
    end

    def catalog_resource
      ::Ci::Catalog::Listing.new(current_user).find_resource(full_path: params[:full_path])
    end

    def tracking_namespace_source
      current_user.namespace
    end

    def tracking_project_source
      nil
    end
  end
end
