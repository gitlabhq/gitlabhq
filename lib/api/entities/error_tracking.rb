# frozen_string_literal: true

module API
  module Entities
    module ErrorTracking
      class ProjectSetting < Grape::Entity
        expose :enabled, as: :active
        expose :project_name
        expose :sentry_external_url
        expose :api_url
        expose :integrated

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
