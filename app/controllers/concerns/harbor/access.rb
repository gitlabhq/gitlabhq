# frozen_string_literal: true

module Harbor
  module Access
    extend ActiveSupport::Concern

    included do
      before_action :harbor_registry_enabled!
      before_action :authorize_read_harbor_registry!
      before_action do
        push_frontend_feature_flag(:harbor_registry_integration)
      end

      feature_category :integrations
    end

    private

    def harbor_registry_enabled!
      render_404 unless Feature.enabled?(:harbor_registry_integration, defined?(group) ? group : project)
    end

    def authorize_read_harbor_registry!
      raise NotImplementedError
    end
  end
end
