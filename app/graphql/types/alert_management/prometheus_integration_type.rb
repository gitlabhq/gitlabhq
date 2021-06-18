# frozen_string_literal: true

module Types
  module AlertManagement
    class PrometheusIntegrationType < ::Types::BaseObject
      include ::Gitlab::Routing

      graphql_name 'AlertManagementPrometheusIntegration'
      description 'An endpoint and credentials used to accept Prometheus alerts for a project'

      implements(Types::AlertManagement::IntegrationType)

      authorize :admin_project

      alias_method :prometheus_integration, :object

      def name
        prometheus_integration.title
      end

      def type
        :prometheus
      end

      def token
        prometheus_integration.project&.alerting_setting&.token
      end

      def url
        prometheus_integration.project && notify_project_prometheus_alerts_url(prometheus_integration.project, format: :json)
      end

      def active
        prometheus_integration.manual_configuration?
      end
    end
  end
end
