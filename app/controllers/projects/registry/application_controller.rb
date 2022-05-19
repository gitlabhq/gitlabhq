# frozen_string_literal: true

module Projects
  module Registry
    class ApplicationController < Projects::ApplicationController
      layout 'project'

      before_action :verify_registry_enabled!
      before_action :authorize_read_container_image!

      feature_category :container_registry
      urgency :low

      private

      def verify_registry_enabled!
        render_404 unless Gitlab.config.registry.enabled
      end
    end
  end
end
