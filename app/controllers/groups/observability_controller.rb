# frozen_string_literal: true

module Groups
  class ObservabilityController < Groups::ApplicationController
    before_action :authenticate_user!
    before_action :authorize_read_observability!

    feature_category :observability
    urgency :low

    content_security_policy_with_context do |p|
      o11y_url = group.observability_group_o11y_setting&.o11y_service_url
      next unless o11y_url.present?

      existing_frame_src = p.directives['frame-src']
      frame_src_values = Array.wrap(existing_frame_src) | ["'self'", o11y_url]
      p.frame_src(*frame_src_values)
    end

    VALID_PATHS = ::Observability::ObservabilityPresenter::PATHS.keys.freeze

    def show
      path = permitted_params[:id]
      return render_404 unless VALID_PATHS.include?(path)

      @data = ::Observability::ObservabilityPresenter.new(group, path)
      render
    end

    private

    def permitted_params
      params.permit(:id)
    end

    def authorize_read_observability!
      return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

      render_404 unless Ability.allowed?(current_user, :read_observability_portal, group)
    end
  end
end
