# frozen_string_literal: true

module Ci
  module Observability
    class ExportService
      include Gitlab::Utils::StrongMemoize

      OBSERVABILITY_VARIABLE = 'GITLAB_OBSERVABILITY_EXPORT'
      VALID_VARIABLE_VALUES = %w[traces metrics logs].freeze

      def initialize(pipeline)
        @pipeline = pipeline
      end

      def execute
        return unless should_export? && observability_available?

        export_data
      rescue StandardError => e
        Gitlab::AppLogger.error(
          message: "GitLab Observability export failed",
          pipeline_id: pipeline.id,
          project_id: pipeline.project_id,
          error_class: e.class.name,
          error_message: e.message
        )
      end

      private

      attr_reader :pipeline

      def should_export?
        export_types.present?
      end

      def observability_available?
        observability_settings.present?
      end

      def observability_settings
        ::Observability::GroupO11ySetting.observability_setting_for(pipeline.project)
      end
      strong_memoize_attr :observability_settings

      def export_types
        build = pipeline.builds.first
        return [] unless build

        variables = pipeline.variables_builder.scoped_variables(
          build,
          environment: nil,
          dependencies: false
        )

        export_variable = variables.find { |var| var.key == OBSERVABILITY_VARIABLE }
        return [] unless export_variable.present?

        export_variable.value.to_s.downcase.split(',').map(&:strip) & VALID_VARIABLE_VALUES
      end
      strong_memoize_attr :export_types

      def export_data
        pipeline_data = Gitlab::DataBuilder::Pipeline.build(pipeline)

        export_types.each do |export_type|
          case export_type
          when 'traces'
            export_traces(pipeline_data)
          when 'metrics'
            export_metrics(pipeline_data)
          when 'logs'
            export_logs(pipeline_data)
          end
        end
      end

      def export_traces(pipeline_data)
        traces_data = Gitlab::Observability::PipelineToTraces.new(integration, pipeline_data).convert
        exporter.export_traces(traces_data) if traces_data.present?
      end

      def export_metrics(pipeline_data)
        metrics_data = Gitlab::Observability::PipelineToMetrics.new(integration, pipeline_data).convert
        exporter.export_metrics(metrics_data) if metrics_data.present?
      end

      def export_logs(pipeline_data)
        logs_data = Gitlab::Observability::PipelineToLogs.new(integration, pipeline_data).convert
        exporter.export_logs(logs_data) if logs_data.present?
      end

      def integration
        Struct.new(
          :otel_endpoint_url,
          :otel_headers,
          :service_name,
          :environment
        ).new(
          otel_endpoint_url,
          otel_headers,
          'gitlab-ci',
          Rails.env
        )
      end
      strong_memoize_attr :integration

      def exporter
        Gitlab::Observability::OtelExporter.new(integration)
      end
      strong_memoize_attr :exporter

      def otel_endpoint_url
        observability_settings.otel_http_endpoint
      end

      def otel_headers
        {}
      end
    end
  end
end
