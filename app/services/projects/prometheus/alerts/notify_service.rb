# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService
        include Gitlab::Utils::StrongMemoize
        include ::IncidentManagement::Settings

        # This set of keys identifies a payload as a valid Prometheus
        # payload and thus processable by this service. See also
        # https://prometheus.io/docs/alerting/configuration/#webhook_config
        REQUIRED_PAYLOAD_KEYS = %w[
          version groupKey status receiver groupLabels commonLabels
          commonAnnotations externalURL alerts
        ].to_set.freeze

        SUPPORTED_VERSION = '4'

        def initialize(project, payload)
          @project = project
          @payload = payload
        end

        def execute(token, integration = nil)
          return bad_request unless valid_payload_size?
          return unprocessable_entity unless self.class.processable?(payload)
          return unauthorized unless valid_alert_manager_token?(token, integration)

          process_prometheus_alerts

          ServiceResponse.success
        end

        def self.processable?(payload)
          # Workaround for https://gitlab.com/gitlab-org/gitlab/-/issues/220496
          return false unless payload

          REQUIRED_PAYLOAD_KEYS.subset?(payload.keys.to_set) &&
            payload['version'] == SUPPORTED_VERSION
        end

        private

        attr_reader :project, :payload

        def valid_payload_size?
          Gitlab::Utils::DeepSize.new(payload).valid?
        end

        def firings
          @firings ||= alerts_by_status('firing')
        end

        def alerts_by_status(status)
          alerts.select { |alert| alert['status'] == status }
        end

        def alerts
          payload['alerts']
        end

        def valid_alert_manager_token?(token, integration)
          valid_for_manual?(token) ||
            valid_for_alerts_endpoint?(token, integration) ||
            valid_for_cluster?(token)
        end

        def valid_for_manual?(token)
          prometheus = project.find_or_initialize_integration('prometheus')
          return false unless prometheus.manual_configuration?

          if setting = project.alerting_setting
            compare_token(token, setting.token)
          else
            token.nil?
          end
        end

        def valid_for_alerts_endpoint?(token, integration)
          return false unless integration&.active?

          compare_token(token, integration.token)
        end

        def valid_for_cluster?(token)
          cluster_integration = find_cluster_integration(project)
          return false unless cluster_integration

          cluster_integration_token = cluster_integration.alert_manager_token

          if token
            compare_token(token, cluster_integration_token)
          else
            cluster_integration_token.nil?
          end
        end

        def find_cluster_integration(project)
          alert_id = gitlab_alert_id
          return unless alert_id

          alert = find_alert(project, alert_id)
          return unless alert

          cluster = alert.environment.deployment_platform&.cluster
          return unless cluster&.enabled?
          return unless cluster.integration_prometheus_available?

          cluster.integration_prometheus
        end

        def find_alert(project, metric)
          Projects::Prometheus::AlertsFinder
            .new(project: project, metric: metric)
            .execute
            .first
        end

        def gitlab_alert_id
          alerts&.first&.dig('labels', 'gitlab_alert_id')
        end

        def compare_token(expected, actual)
          return unless expected && actual

          ActiveSupport::SecurityUtils.secure_compare(expected, actual)
        end

        def process_prometheus_alerts
          alerts.each do |alert|
            AlertManagement::ProcessPrometheusAlertService
              .new(project, alert.to_h)
              .execute
          end
        end

        def bad_request
          ServiceResponse.error(message: 'Bad Request', http_status: :bad_request)
        end

        def unauthorized
          ServiceResponse.error(message: 'Unauthorized', http_status: :unauthorized)
        end

        def unprocessable_entity
          ServiceResponse.error(message: 'Unprocessable Entity', http_status: :unprocessable_entity)
        end
      end
    end
  end
end
