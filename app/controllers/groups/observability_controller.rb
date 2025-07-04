# frozen_string_literal: true

module Groups
  class ObservabilityController < Groups::ApplicationController
    content_security_policy do |p|
      next if p.directives.blank? || ENV['O11Y_URL'].blank?

      frame_src_values = Array.wrap(p.directives['frame-src']) | ["'self'", ENV['O11Y_URL'].to_s]
      p.frame_src(*frame_src_values)
    end

    before_action :authenticate_user!
    before_action :authorize_read_observability!

    feature_category :observability
    urgency :low

    VALID_PATHS = %w[
      services
      traces-explorer
      logs/logs-explorer
      metrics-explorer/summary
      infrastructure-monitoring/hosts
      dashboard
      messaging-queues
      api-monitoring/explorer
      alerts
      exceptions
      service-map
      settings
    ].freeze

    def show
      @o11y_url = ENV['O11Y_URL']

      @path = permitted_params[:id]

      return render_404 unless VALID_PATHS.include?(@path)

      render
    end

    private

    def permitted_params
      params.permit(:id)
    end

    def authorize_read_observability!
      return render_404 unless ::Feature.enabled?(:observability_sass_features, group)

      render_404 unless current_user.can?(:maintainer_access, group)
    end
  end
end
