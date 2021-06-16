# frozen_string_literal: true

# DEPRECATED: To be removed as part of https://gitlab.com/groups/gitlab-org/-/epics/5877
module Prometheus
  class CreateDefaultAlertsService < BaseService
    include Gitlab::Utils::StrongMemoize

    attr_reader :project

    DEFAULT_ALERTS = [
      {
        identifier: 'response_metrics_nginx_ingress_16_http_error_rate',
        operator: 'gt',
        threshold: 0.1
      },
      {
        identifier: 'response_metrics_nginx_ingress_http_error_rate',
        operator: 'gt',
        threshold: 0.1
      },
      {
        identifier: 'response_metrics_nginx_http_error_percentage',
        operator: 'gt',
        threshold: 0.1
      }
    ].freeze

    def initialize(project:)
      @project = project
    end

    def execute
      return ServiceResponse.error(message: 'Invalid project') unless project
      return ServiceResponse.error(message: 'Invalid environment') unless environment

      create_alerts
      schedule_prometheus_update

      ServiceResponse.success
    end

    private

    def create_alerts
      DEFAULT_ALERTS.each do |alert_hash|
        identifier = alert_hash[:identifier]
        next if alerts_by_identifier(environment).key?(identifier)

        metric = metrics_by_identifier[identifier]
        next unless metric

        create_alert(alert: alert_hash, metric: metric)
      end
    end

    def schedule_prometheus_update
      return unless prometheus_adapter

      ::Clusters::Applications::ScheduleUpdateService.new(prometheus_adapter, project).execute
    end

    def prometheus_adapter
      environment.cluster_prometheus_adapter
    end

    def metrics_by_identifier
      strong_memoize(:metrics_by_identifier) do
        metric_identifiers = DEFAULT_ALERTS.map { |alert| alert[:identifier] }

        PrometheusMetricsFinder
          .new(identifier: metric_identifiers, common: true)
          .execute
          .index_by(&:identifier)
      end
    end

    def alerts_by_identifier(environment)
      strong_memoize(:alerts_by_identifier) do
        Projects::Prometheus::AlertsFinder
          .new(project: project, metric: metrics_by_identifier.values, environment: environment)
          .execute
          .index_by { |alert| alert.prometheus_metric.identifier }
      end
    end

    def environment
      strong_memoize(:environment) do
        Environments::EnvironmentsFinder.new(project, nil, name: 'production').execute.first ||
          project.environments.first
      end
    end

    def create_alert(alert:, metric:)
      PrometheusAlert.create!(
        project: project,
        prometheus_metric: metric,
        environment: environment,
        threshold: alert[:threshold],
        operator: alert[:operator]
      )
    rescue ActiveRecord::RecordNotUnique
      # Ignore duplicate creations although it unlikely to happen
    end
  end
end
