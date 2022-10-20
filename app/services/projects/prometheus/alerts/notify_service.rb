# frozen_string_literal: true

module Projects
  module Prometheus
    module Alerts
      class NotifyService < ::BaseProjectService
        include Gitlab::Utils::StrongMemoize
        include ::AlertManagement::Responses

        # This set of keys identifies a payload as a valid Prometheus
        # payload and thus processable by this service. See also
        # https://prometheus.io/docs/alerting/configuration/#webhook_config
        REQUIRED_PAYLOAD_KEYS = %w[
          version groupKey status receiver groupLabels commonLabels
          commonAnnotations externalURL alerts
        ].to_set.freeze

        SUPPORTED_VERSION = '4'

        # If feature flag :prometheus_notify_max_alerts is enabled truncate
        # alerts to 100 and process only them.
        # If feature flag is disabled process any amount of alerts.
        #
        # This is to mitigate incident:
        # https://gitlab.com/gitlab-com/gl-infra/production/-/issues/6086
        PROCESS_MAX_ALERTS = 100

        def initialize(project, params)
          super(project: project, params: params.to_h)
        end

        def execute(token, integration = nil)
          return bad_request unless valid_payload_size?
          return unprocessable_entity unless self.class.processable?(params)
          return unauthorized unless valid_alert_manager_token?(token, integration)

          truncate_alerts! if max_alerts_exceeded?

          process_prometheus_alerts

          created
        end

        def self.processable?(payload)
          # Workaround for https://gitlab.com/gitlab-org/gitlab/-/issues/220496
          return false unless payload

          REQUIRED_PAYLOAD_KEYS.subset?(payload.keys.to_set) &&
            payload['version'] == SUPPORTED_VERSION
        end

        private

        def valid_payload_size?
          Gitlab::Utils::DeepSize.new(params).valid?
        end

        def max_alerts_exceeded?
          return false unless Feature.enabled?(:prometheus_notify_max_alerts, project, type: :ops)

          alerts.size > PROCESS_MAX_ALERTS
        end

        def truncate_alerts!
          Gitlab::AppLogger.warn(
            message: 'Prometheus payload exceeded maximum amount of alerts. Truncating alerts.',
            project_id: project.id,
            alerts: {
              total: alerts.size,
              max: PROCESS_MAX_ALERTS
            }
          )

          params['alerts'] = alerts.first(PROCESS_MAX_ALERTS)
        end

        def alerts
          params['alerts']
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
          alerts.map do |alert|
            AlertManagement::ProcessPrometheusAlertService
              .new(project, alert)
              .execute
          end
        end
      end
    end
  end
end
