# frozen_string_literal: true

module Projects
  module Harbor
    class ApplicationController < Projects::ApplicationController
      layout 'project'

      before_action :harbor_registry_enabled!
      before_action do
        push_frontend_feature_flag(:harbor_registry_integration)
      end

      feature_category :integrations

      private

      def harbor_registry_enabled!
        render_404 unless Feature.enabled?(:harbor_registry_integration)
      end
    end
  end
end
