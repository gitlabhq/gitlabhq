# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToLogs < PipelineConverterBase
      def convert
        return empty_logs_payload if @pipeline.blank?

        {
          resourceLogs: [
            {
              resource: build_resource,
              scopeLogs: [
                {
                  scope: build_scope,
                  logRecords: build_log_records
                }
              ]
            }
          ]
        }
      end

      private

      def empty_logs_payload
        { resourceLogs: [] }
      end

      def build_resource
        {
          attributes: compact_attributes(
            resource_semconv
          )
        }
      end

      def build_scope
        {
          name: 'gitlab-ci-logs',
          version: '1.0.0'
        }
      end

      def build_log_records
        [build_pipeline_log] + builds.map { |build| build_job_log(build) }
      end

      def build_pipeline_log
        {
          traceId: pipeline_trace_id,
          spanId: pipeline_span_id,
          flags: 1,
          timeUnixNano: time_to_nanoseconds(pipeline[:finished_at] || pipeline[:created_at]),
          severityNumber: map_severity(pipeline[:status]),
          severityText: map_severity_text(pipeline[:status]),
          body: {
            stringValue: "Pipeline #{pipeline[:status]}: #{pipeline[:name] || pipeline[:ref]}"
          },
          attributes: compact_attributes(
            [
              { key: 'log.level', value: { stringValue: map_severity_text(pipeline[:status]) } },
              { key: 'log.source', value: { stringValue: 'pipeline' } }
            ] + pipeline_legacy_attributes + pipeline_semconv_attributes
          )
        }
      end

      def build_job_log(build)
        {
          traceId: pipeline_trace_id,
          spanId: job_span_id(build),
          flags: 1,
          timeUnixNano: time_to_nanoseconds(build[:finished_at] || build[:started_at] || build[:created_at]),
          severityNumber: map_severity(build[:status]),
          severityText: map_severity_text(build[:status]),
          body: {
            stringValue: "Job #{build[:status]}: #{build[:name]} (#{build[:stage]})"
          },
          attributes: compact_attributes(
            [
              { key: 'log.level', value: { stringValue: map_severity_text(build[:status]) } },
              { key: 'log.source', value: { stringValue: 'job' } }
            ] +
              job_legacy_attributes(build) +
              job_semconv_attributes(build)
          )
        }
      end

      def map_severity(status)
        case status
        when 'success'
          9
        when 'failed'
          17
        when 'canceled'
          13
        else
          5
        end
      end

      def map_severity_text(status)
        case status
        when 'success'
          'INFO'
        when 'failed'
          'ERROR'
        when 'canceled'
          'WARN'
        else
          'DEBUG'
        end
      end
    end
  end
end
