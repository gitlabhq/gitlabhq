# frozen_string_literal: true

module Groups
  module Harbor
    class RepositoriesController < Groups::ApplicationController
      feature_category :integrations

      before_action :harbor_registry_enabled!
      before_action do
        push_frontend_feature_flag(:harbor_registry_integration)
      end

      def show
        render :index
      end

      private

      def harbor_registry_enabled!
        render_404 unless Feature.enabled?(:harbor_registry_integration)
      end
    end
  end
end
