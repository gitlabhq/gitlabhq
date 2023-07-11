# frozen_string_literal: true

module Projects
  class TracingController < Projects::ApplicationController
    include ::Observability::ContentSecurityPolicy

    feature_category :tracing

    before_action :check_tracing_enabled

    def index
      # TODO frontend changes coming separately https://gitlab.com/gitlab-org/gitlab/-/merge_requests/125014
      render html: helpers.tag.strong('Tracing')
    end

    private

    def check_tracing_enabled
      render_404 unless Gitlab::Observability.tracing_enabled?(project)
    end
  end
end
