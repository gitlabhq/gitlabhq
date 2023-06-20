# frozen_string_literal: true

module API
  module Entities
    module ErrorTracking
      class ProjectSetting < Grape::Entity
        expose :enabled, as: :active, documentation: { type: 'boolean' }
        expose :project_name, documentation: { type: 'string', example: 'sample sentry project' }
        expose :sentry_external_url, documentation: { type: 'string', example: 'https://sentry.io/myawesomeproject/project' }
        expose :api_url, documentation: { type: 'string', example: 'https://sentry.io/api/0/projects/myawesomeproject/project' }
        expose :integrated, documentation: { type: 'boolean' }

        def integrated
          return false unless ::Feature.enabled?(:integrated_error_tracking, object.project)

          object.integrated_client?
        end
      end

      class ClientKey < Grape::Entity
        expose :id, documentation: { type: 'integer', example: 1 }
        expose :active, documentation: { type: 'boolean' }
        expose :public_key, documentation: { type: 'string', example: 'glet_aa77551d849c083f76d0bc545ed053a3' }
        expose :sentry_dsn, documentation: { type: 'string', example: 'https://glet_aa77551d849c083f76d0bc545ed053a3@example.com/errortracking/api/v1/projects/5' }
      end
    end
  end
end
