# frozen_string_literal: true

module Projects
  class TracingController < Projects::ApplicationController
    include ::Observability::ContentSecurityPolicy

    feature_category :tracing

    before_action :check_tracing_enabled

    def index; end

    def show
      @trace_id = params[:id]
    end

    private

    def check_tracing_enabled
      render_404 unless Gitlab::Observability.tracing_enabled?(project)
    end
  end
end
