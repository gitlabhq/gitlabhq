# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToTraces < PipelineConverterBase
      def convert
        return empty_traces_payload if @pipeline.blank?

        {
          resourceSpans: [
            {
              resource: build_resource,
              scopeSpans: [
                {
                  scope: build_scope,
                  spans: build_spans
                }
              ]
            }
          ]
        }
      end

      private

      def empty_traces_payload
        { resourceSpans: [] }
      end

      def build_resource
        {
          attributes: compact_attributes(resource_semconv)
        }
      end

      def build_scope
        {
          name: 'gitlab-ci-pipeline',
          version: '1.0.0'
        }
      end

      def build_spans
        spans = [build_pipeline_span]
        builds.each { |build| spans << build_job_span(build) }
        spans
      end

      def build_pipeline_span
        {
          traceId: pipeline_trace_id,
          spanId: pipeline_span_id,
          parentSpanId: parent_span_id_for_pipeline,
          name: "pipeline: #{pipeline[:name] || pipeline[:ref]}",
          kind: 1,
          startTimeUnixNano: time_to_nanoseconds(pipeline[:created_at]),
          endTimeUnixNano: time_to_nanoseconds(pipeline[:finished_at]),
          status: build_pipeline_status,
          attributes: compact_attributes(pipeline_legacy_attributes + pipeline_semconv_attributes)
        }
      end

      def build_job_span(build)
        {
          traceId: pipeline_trace_id,
          spanId: exported_span_id(build),
          parentSpanId: pipeline_span_id,
          name: "job: #{build[:name]}",
          kind: 1,
          startTimeUnixNano: time_to_nanoseconds(build[:started_at]),
          endTimeUnixNano: time_to_nanoseconds(build[:finished_at]),
          status: build_job_status(build),
          attributes: compact_attributes(job_legacy_attributes(build) + job_semconv_attributes(build))
        }
      end

      def parent_span_id_for_pipeline
        return '' unless pipeline_data[:trace_correlation_enabled]

        bridge_id = pipeline_data.dig(:source_pipeline, :bridge_id)
        return '' unless bridge_id

        source_project_id = pipeline_data.dig(:source_pipeline, :project, :id)
        current_project_id = pipeline_data.dig(:project, :id)
        return '' unless source_project_id == current_project_id

        Gitlab::Ci::TraceContext.span_id_for_bridge(bridge_id)
      end

      def build_pipeline_status
        build_status(pipeline[:status], pipeline[:failure_reason])
      end

      def build_job_status(build)
        build_status(build[:status], build[:failure_reason])
      end

      def build_status(status, message = nil)
        status_obj = case status
                     when 'success'
                       { code: 'STATUS_CODE_OK' }
                     when 'failed', 'canceled'
                       { code: 'STATUS_CODE_ERROR' }
                     else
                       { code: 'STATUS_CODE_UNSET' }
                     end

        status_obj[:message] = message if message.present?
        status_obj
      end
    end
  end
end
