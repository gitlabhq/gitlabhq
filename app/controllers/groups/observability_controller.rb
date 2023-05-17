# frozen_string_literal: true
module Groups
  class ObservabilityController < Groups::ApplicationController
    include ::Observability::ContentSecurityPolicy

    feature_category :tracing

    before_action :check_observability_allowed

    def dashboards
      render_observability
    end

    def manage
      render_observability
    end

    def explore
      render_observability
    end

    def datasources
      render_observability
    end

    private

    def render_observability
      render 'observability', layout: 'group', locals: { base_layout: 'layouts/fullscreen' }
    end

    def check_observability_allowed
      render_404 unless Gitlab::Observability.allowed_for_action?(current_user, group, params[:action])
    end
  end
end
