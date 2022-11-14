# frozen_string_literal: true

module API
  module Entities
    module Metrics
      class UserStarredDashboard < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 5 }
        expose :dashboard_path, documentation: { type: 'string', example: 'config/prometheus/common_metrics.yml' }
        expose :user_id, documentation: { type: 'integer', example: 1 }
        expose :project_id, documentation: { type: 'integer', example: 20 }
      end
    end
  end
end
