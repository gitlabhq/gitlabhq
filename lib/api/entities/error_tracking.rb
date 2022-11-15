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
        expose :id
        expose :active
        expose :public_key
        expose :sentry_dsn
      end
    end
  end
end
