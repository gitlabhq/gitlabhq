# frozen_string_literal: true

module Projects
  module Integrations
    class ShimosController < Projects::ApplicationController
      feature_category :integrations

      before_action :ensure_renderable

      def show; end

      private

      def ensure_renderable
        render_404 unless project.has_shimo? && project.shimo_integration&.render?
      end
    end
  end
end
