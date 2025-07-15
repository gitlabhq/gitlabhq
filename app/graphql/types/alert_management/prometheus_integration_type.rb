# frozen_string_literal: true

# Deprecated:
#   Remove with PrometheusIntegration mutations during any major release.
module Types
  module AlertManagement
    class PrometheusIntegrationType < ::Types::BaseObject
      graphql_name 'AlertManagementPrometheusIntegration'
      description '**DEPRECATED - Use AlertManagementHttpIntegration directly** An endpoint and credentials used to accept Prometheus alerts for a project'

      implements Types::AlertManagement::IntegrationType

      authorize :admin_operations
    end
  end
end
