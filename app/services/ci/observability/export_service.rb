# frozen_string_literal: true

module Ci
  module Observability
    class ExportService
      include Gitlab::Utils::StrongMemoize

      OBSERVABILITY_VARIABLE = 'GITLAB_OBSERVABILITY_EXPORT'
      OBSERVABILITY_TOKEN_VARIABLE = 'GITLAB_OBSERVABILITY_TOKEN'
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

      def scoped_variables
        build = pipeline.builds.first
        return unless build

        pipeline.variables_builder.scoped_variables(
          build,
          environment: nil,
          dependencies: false
        )
      end
      strong_memoize_attr :scoped_variables

      def export_types
        return [] unless scoped_variables

        export_variable = scoped_variables[OBSERVABILITY_VARIABLE]
        return [] unless export_variable.present?

        export_variable.value.to_s.downcase.split(',').map(&:strip) & VALID_VARIABLE_VALUES
      end
      strong_memoize_attr :export_types

      def observability_token
        return unless scoped_variables

        token_variable = scoped_variables[OBSERVABILITY_TOKEN_VARIABLE]
        return unless token_variable.present?

        token = token_variable.value.to_s.strip
        return if token.blank?
        return if token.match?(/[[:cntrl:]]/)

        token
      end
      strong_memoize_attr :observability_token

      def export_data
        pipeline_data = Gitlab::DataBuilder::Pipeline.build(pipeline)
        pipeline_data[:trace_correlation_enabled] = trace_correlation_enabled?

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

      def trace_correlation_enabled?
        Feature.enabled?(:ci_pipeline_otlp_trace_correlation, pipeline.project)
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
        observability_settings.otel_https_endpoint
      end

      def otel_headers
        return {} unless observability_token

        { 'Authorization' => "Bearer #{observability_token}" }
      end
    end
  end
end
