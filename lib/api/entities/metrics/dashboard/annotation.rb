# frozen_string_literal: true

module API
  module Entities
    module Metrics
      module Dashboard
        class Annotation < Grape::Entity
          expose :id, documentation: { type: 'integer', example: 4 }
          expose :starting_at, documentation: { type: 'dateTime', example: '2016-04-08T03:45:40.000Z' }
          expose :ending_at, documentation: { type: 'dateTime', example: '2016-08-08T09:00:00.000Z' }
          expose :dashboard_path, documentation: { type: 'string', example: '.gitlab/dashboards/custom_metrics.yml' }
          expose :description, documentation: { type: 'string', example: 'annotation description' }
          expose :environment_id, documentation: { type: 'integer', example: 1 }
          expose :cluster_id, documentation: { type: 'integer', example: 2 }
        end
      end
    end
  end
end
