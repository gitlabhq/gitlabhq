# frozen_string_literal: true
module Groups
  class ObservabilityController < Groups::ApplicationController
    feature_category :tracing

    content_security_policy do |p|
      next if p.directives.blank?

      default_frame_src = p.directives['frame-src'] || p.directives['default-src']

      # When ObservabilityUI is not authenticated, it needs to be able to redirect to the GL sign-in page, hence 'self'
      frame_src_values = Array.wrap(default_frame_src) | [ObservabilityController.observability_url, "'self'"]

      p.frame_src(*frame_src_values)
    end

    before_action :check_observability_allowed, only: :index

    def index
      # Format: https://observe.gitlab.com/-/GROUP_ID
      @observability_iframe_src = "#{ObservabilityController.observability_url}/-/#{@group.id}"

      # Uncomment below for testing with local GDK
      # @observability_iframe_src = "#{ObservabilityController.observability_url}/9970?groupId=14485840"

      render layout: 'group', locals: { base_layout: 'layouts/fullscreen' }
    end

    private

    def self.observability_url
      return ENV['OVERRIDE_OBSERVABILITY_URL'] if ENV['OVERRIDE_OBSERVABILITY_URL']
      # TODO Make observability URL configurable https://gitlab.com/gitlab-org/opstrace/opstrace-ui/-/issues/80
      return "https://staging.observe.gitlab.com" if Gitlab.staging?

      "https://observe.gitlab.com"
    end

    def check_observability_allowed
      return render_404 unless self.class.observability_url.present?

      render_404 unless can?(current_user, :read_observability, @group)
    end
  end
end
