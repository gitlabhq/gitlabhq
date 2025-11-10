# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToLogs
      include Gitlab::Utils::StrongMemoize

      def initialize(integration, pipeline_data)
        @integration = integration
        @pipeline_data = pipeline_data
        @pipeline = pipeline_data[:object_attributes]
        @builds = pipeline_data[:builds] || []
      end

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

      attr_reader :integration, :pipeline_data, :pipeline, :builds

      def empty_logs_payload
        { resourceLogs: [] }
      end

      def build_resource
        {
          attributes: [
            { key: 'service.name', value: { stringValue: service_name } },
            { key: 'service.version', value: { stringValue: '1.0.0' } },
            { key: 'deployment.environment', value: { stringValue: environment } },

            (if pipeline_data.dig(:project,
              :id)
               { key: 'gitlab.project.id', value: { intValue: pipeline_data.dig(:project, :id) } }
             end),

            { key: 'gitlab.project.name', value: { stringValue: pipeline_data.dig(:project, :name) } },
            (pipeline[:id] ? { key: 'gitlab.pipeline.id', value: { intValue: pipeline[:id] } } : nil),
            { key: 'gitlab.pipeline.ref', value: { stringValue: pipeline[:ref] } }
          ].compact
        }
      end

      def build_scope
        {
          name: 'gitlab-ci-logs',
          version: '1.0.0'
        }
      end

      def build_log_records
        logs = []

        logs << build_pipeline_log

        builds.each do |build|
          logs << build_job_log(build)
        end

        logs
      end

      def build_pipeline_log
        {
          timeUnixNano: time_to_nanoseconds(pipeline[:finished_at] || pipeline[:created_at]),
          severityNumber: map_severity(pipeline[:status]),
          severityText: map_severity_text(pipeline[:status]),
          body: {
            stringValue: "Pipeline #{pipeline[:status]}: #{pipeline[:name] || pipeline[:ref]}"
          },
          attributes: [
            { key: 'log.level', value: { stringValue: map_severity_text(pipeline[:status]) } },
            { key: 'log.source', value: { stringValue: 'pipeline' } },
            (pipeline[:id] ? { key: 'pipeline.id', value: { intValue: pipeline[:id] } } : nil),
            (pipeline[:iid] ? { key: 'pipeline.iid', value: { intValue: pipeline[:iid] } } : nil),
            { key: 'pipeline.name', value: { stringValue: pipeline[:name] || '' } },
            { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } },
            { key: 'pipeline.sha', value: { stringValue: pipeline[:sha] } },
            { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
            { key: 'pipeline.detailed_status', value: { stringValue: pipeline[:detailed_status] } },
            { key: 'pipeline.duration', value: { intValue: (pipeline[:duration] || 0).to_i } },
            { key: 'pipeline.queued_duration', value: { intValue: (pipeline[:queued_duration] || 0).to_i } },
            { key: 'pipeline.protected_ref', value: { boolValue: pipeline[:protected_ref] || false } },
            { key: 'pipeline.url', value: { stringValue: pipeline[:url] } },
            { key: 'pipeline.stages', value: { arrayValue: { values: pipeline[:stages]&.map do |stage|
              { stringValue: stage }
            end || [] } } }
          ].compact
        }
      end

      def build_job_log(build)
        {
          timeUnixNano: time_to_nanoseconds(build[:finished_at] || build[:started_at] || build[:created_at]),
          severityNumber: map_severity(build[:status]),
          severityText: map_severity_text(build[:status]),
          body: {
            stringValue: "Job #{build[:status]}: #{build[:name]} (#{build[:stage]})"
          },
          attributes: build_job_attributes(build)
        }
      end

      def build_job_attributes(build)
        base_attributes = [
          { key: 'log.level', value: { stringValue: map_severity_text(build[:status]) } },
          { key: 'log.source', value: { stringValue: 'job' } },
          (build[:id] ? { key: 'job.id', value: { intValue: build[:id] } } : nil),
          { key: 'job.name', value: { stringValue: build[:name] } },
          { key: 'job.stage', value: { stringValue: build[:stage] } },
          { key: 'job.status', value: { stringValue: build[:status] } },
          { key: 'job.duration', value: { intValue: (build[:duration] || 0).to_i } },
          { key: 'job.queued_duration', value: { intValue: (build[:queued_duration] || 0).to_i } },
          { key: 'job.manual', value: { boolValue: build[:manual] || false } },
          { key: 'job.allow_failure', value: { boolValue: build[:allow_failure] || false } },
          { key: 'job.failure_reason', value: { stringValue: build[:failure_reason] || '' } }
        ]

        base_attributes +
          build_runner_attributes(build) +
          build_environment_attributes(build) +
          build_artifacts_attributes(build)
      end

      def build_runner_attributes(build)
        return [] unless build[:runner]

        [
          (build.dig(:runner, :id) ? { key: 'job.runner.id', value: { intValue: build.dig(:runner, :id) } } : nil),
          { key: 'job.runner.description', value: { stringValue: build.dig(:runner, :description) || '' } },
          { key: 'job.runner.tags', value: { arrayValue: { values: build.dig(:runner, :tags)&.map do |tag|
            { stringValue: tag }
          end || [] } } }
        ].compact
      end

      def build_environment_attributes(build)
        return [] unless build[:environment]

        [
          { key: 'job.environment.name', value: { stringValue: build.dig(:environment, :name) || '' } },
          { key: 'job.environment.action', value: { stringValue: build.dig(:environment, :action) || '' } }
        ]
      end

      def build_artifacts_attributes(build)
        return [] unless build[:artifacts_file]

        [
          { key: 'job.artifacts.filename', value: { stringValue: build.dig(:artifacts_file, :filename) || '' } },
          { key: 'job.artifacts.size', value: { intValue: build.dig(:artifacts_file, :size) || 0 } }
        ]
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

      def service_name
        integration.service_name.presence || pipeline_data.dig(:project, :name) || 'gitlab-ci'
      end

      def environment
        integration.environment.presence || 'production'
      end

      def time_to_nanoseconds(active_support_time_value)
        return 0 if active_support_time_value.blank?

        active_support_time_value.to_i * 1_000_000_000
      rescue ArgumentError
        Time.current.to_i * 1_000_000_000
      end
    end
  end
end
