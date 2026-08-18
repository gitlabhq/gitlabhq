# frozen_string_literal: true

module Gitlab
  module Observability
    # Shared trace context helpers for pipeline OTLP converters.
    #
    # Provides deterministic trace_id and span_id derivation methods
    # used by PipelineToTraces, PipelineToLogs, and PipelineToMetrics
    # to ensure cross-signal correlation (traces <-> logs <-> metrics).
    #
    # Expects the including class to define:
    #   - pipeline_data (Hash) - the pipeline webhook payload
    #   - pipeline (Hash) - pipeline_data[:object_attributes]
    module TracingHelpers
      extend ActiveSupport::Concern

      included do
        private

        def pipeline_trace_id
          Gitlab::Ci::TraceContext.trace_id_for(root_pipeline_id)
        end
        strong_memoize_attr :pipeline_trace_id

        def root_pipeline_id
          explicit_id = pipeline_data.dig(:object_attributes, :root_pipeline_id)
          return explicit_id unless explicit_id.nil?

          if pipeline_data[:trace_correlation_enabled] && pipeline_data.key?(:source_pipeline)
            Gitlab::AppLogger.warn(
              message: 'root_pipeline_id missing from pipeline webhook payload with source_pipeline present',
              gl_pipeline_id: pipeline[:id],
              "source_pipeline.pipeline_id": pipeline_data.dig(:source_pipeline, :pipeline_id)
            )
          end

          pipeline[:id]
        end
        strong_memoize_attr :root_pipeline_id

        def pipeline_span_id
          Gitlab::Ci::TraceContext.span_id_for_pipeline(root_pipeline_id, pipeline[:id])
        end
        strong_memoize_attr :pipeline_span_id

        def job_span_id(build)
          # Uses :export kind to produce span IDs in the observability export
          # namespace. This is intentionally distinct from the EE job telemetry
          # span kinds (:lifecycle, :pending, :running) so that export spans
          # and real-time telemetry spans coexist without ID collisions.
          Gitlab::Ci::TraceContext.span_id_for_job(root_pipeline_id, build[:id], :export)
        end
      end
    end
  end
end
