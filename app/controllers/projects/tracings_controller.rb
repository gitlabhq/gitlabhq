# frozen_string_literal: true

module Projects
  class TracingsController < Projects::ApplicationController
    content_security_policy do |p|
      next if p.directives.blank?

      global_frame_src = p.frame_src

      p.frame_src -> { frame_src_csp_policy(global_frame_src) }
    end

    before_action :authorize_update_environment!

    feature_category :tracing

    def show
    end

    private

    def frame_src_csp_policy(global_frame_src)
      external_url = @project&.tracing_setting&.external_url

      external_url.presence || global_frame_src
    end
  end
end
