# frozen_string_literal: true

module Types
  module AlertManagement
    class PrometheusIntegrationType < ::Types::BaseObject
      include ::Gitlab::Routing

      graphql_name 'AlertManagementPrometheusIntegration'
      description 'An endpoint and credentials used to accept Prometheus alerts for a project'

      implements(Types::AlertManagement::IntegrationType)

      authorize :admin_project

      alias_method :prometheus_service, :object

      def name
        prometheus_service.title
      end

      def type
        :prometheus
      end

      def token
        prometheus_service.project&.alerting_setting&.token
      end

      def url
        prometheus_service.project && notify_project_prometheus_alerts_url(prometheus_service.project, format: :json)
      end

      def active
        prometheus_service.manual_configuration?
      end
    end
  end
end
