# frozen_string_literal: true

# Ingest YAML fragment with metrics dashboard panel definition
# https://docs.gitlab.com/ee/operations/metrics/dashboards/yaml.html#panel-panels-properties
# process it and returns renderable json version
module Metrics
  module Dashboard
    class PanelPreviewService
      SEQUENCE = [
        ::Gitlab::Metrics::Dashboard::Stages::CommonMetricsInserter,
        ::Gitlab::Metrics::Dashboard::Stages::MetricEndpointInserter,
        ::Gitlab::Metrics::Dashboard::Stages::PanelIdsInserter,
        ::Gitlab::Metrics::Dashboard::Stages::AlertsInserter,
        ::Gitlab::Metrics::Dashboard::Stages::UrlValidator
      ].freeze

      HANDLED_PROCESSING_ERRORS = [
        Gitlab::Metrics::Dashboard::Errors::DashboardProcessingError,
        Gitlab::Config::Loader::Yaml::NotHashError,
        Gitlab::Config::Loader::Yaml::DataTooLargeError,
        Gitlab::Config::Loader::FormatError
      ].freeze

      def initialize(project, panel_yaml, environment)
        @project = project
        @panel_yaml = panel_yaml
        @environment = environment
      end

      def execute
        dashboard = ::Gitlab::Metrics::Dashboard::Processor.new(project, dashboard_structure, SEQUENCE, environment: environment).process
        ServiceResponse.success(payload: dashboard[:panel_groups][0][:panels][0])
      rescue *HANDLED_PROCESSING_ERRORS => error
        ServiceResponse.error(message: error.message)
      end

      private

      attr_accessor :project, :panel_yaml, :environment

      def dashboard_structure
        {
          panel_groups: [
            {
              panels: [panel_hash]
            }
          ]
        }
      end

      def panel_hash
        ::Gitlab::Config::Loader::Yaml.new(panel_yaml).load_raw!
      end
    end
  end
end
