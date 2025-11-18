# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToTraces
      include Gitlab::Utils::StrongMemoize

      def initialize(integration, pipeline_data)
        @integration = integration
        @pipeline_data = pipeline_data
        @pipeline = pipeline_data[:object_attributes]
        @builds = pipeline_data[:builds] || []
      end

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

      attr_reader :integration, :pipeline_data, :pipeline, :builds

      def empty_traces_payload
        { resourceSpans: [] }
      end

      def build_resource
        {
          attributes: [
            { key: 'service.name', value: { stringValue: service_name } },
            { key: 'service.version', value: { stringValue: '1.0.0' } },
            { key: 'deployment.environment', value: { stringValue: environment } },
            { key: 'gitlab.project.id', value: { intValue: pipeline_data.dig(:project, :id) } },
            { key: 'gitlab.project.name', value: { stringValue: pipeline_data.dig(:project, :name) } },
            { key: 'gitlab.project.path', value: { stringValue: pipeline_data.dig(:project, :path_with_namespace) } },
            { key: 'gitlab.pipeline.id', value: { intValue: pipeline[:id] } },
            { key: 'gitlab.pipeline.ref', value: { stringValue: pipeline[:ref] } },
            { key: 'gitlab.pipeline.source', value: { stringValue: pipeline[:source] } }
          ]
        }
      end

      def build_scope
        {
          name: 'gitlab-ci-pipeline',
          version: '1.0.0'
        }
      end

      def build_spans
        pipeline_span = build_pipeline_span
        spans = [pipeline_span]

        builds.each do |build|
          spans << build_job_span(build)
        end

        spans
      end

      def build_pipeline_span
        {
          traceId: pipeline_trace_id,
          spanId: pipeline_span_id,
          parentSpanId: '',
          name: "pipeline: #{pipeline[:name] || pipeline[:ref]}",
          kind: 1,
          startTimeUnixNano: time_to_nanoseconds(pipeline[:created_at]),
          endTimeUnixNano: time_to_nanoseconds(pipeline[:finished_at]),
          status: build_pipeline_status,
          attributes: build_pipeline_attributes
        }
      end

      def build_job_span(build)
        {
          traceId: pipeline_trace_id,
          spanId: generate_span_id,
          parentSpanId: pipeline_span_id,
          name: "job: #{build[:name]}",
          kind: 1,
          startTimeUnixNano: time_to_nanoseconds(build[:started_at]),
          endTimeUnixNano: time_to_nanoseconds(build[:finished_at]),
          status: build_job_status(build),
          attributes: build_job_attributes(build)
        }
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

      def build_pipeline_attributes
        base_attributes = build_base_pipeline_attributes
        optional_attributes = build_optional_pipeline_attributes

        base_attributes + optional_attributes
      end

      def build_base_pipeline_attributes
        [
          { key: 'pipeline.id', value: { intValue: pipeline[:id] } },
          { key: 'pipeline.iid', value: { intValue: pipeline[:iid] } },
          { key: 'pipeline.name', value: { stringValue: pipeline[:name] || '' } },
          { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } },
          { key: 'pipeline.sha', value: { stringValue: pipeline[:sha] } },
          { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
          { key: 'pipeline.detailed_status', value: { stringValue: pipeline[:detailed_status] || '' } },
          { key: 'pipeline.duration', value: { intValue: (pipeline[:duration] || 0).to_i } },
          { key: 'pipeline.queued_duration', value: { intValue: (pipeline[:queued_duration] || 0).to_i } },
          { key: 'pipeline.protected_ref', value: { boolValue: pipeline[:protected_ref] || false } },
          { key: 'pipeline.url', value: { stringValue: pipeline[:url] || '' } }
        ]
      end

      def build_optional_pipeline_attributes
        attrs = []
        attrs += build_pipeline_specific_attributes
        attrs += build_pipeline_user_attributes
        attrs += build_pipeline_commit_attributes
        attrs += build_pipeline_merge_request_attributes
        attrs += build_pipeline_source_pipeline_attributes
        attrs
      end

      def build_pipeline_specific_attributes
        attrs = []
        attrs << { key: 'pipeline.tag', value: { boolValue: pipeline[:tag] || false } } if pipeline.key?(:tag)

        if pipeline[:before_sha].present?
          attrs << { key: 'pipeline.before_sha', value: { stringValue: pipeline[:before_sha] } }
        end

        if pipeline[:stages].present?
          attrs << { key: 'pipeline.stages', value: { arrayValue: { values: pipeline[:stages]&.map do |stage|
            { stringValue: stage }
          end || [] } } }
        end

        attrs
      end

      def build_pipeline_user_attributes
        attrs = []
        if pipeline_data.dig(:user, :id)
          attrs << { key: 'pipeline.user.id', value: { intValue: pipeline_data.dig(:user, :id) } }
        end

        if pipeline_data.dig(:user, :username)
          attrs << { key: 'pipeline.user.username', value: { stringValue: pipeline_data.dig(:user, :username) || '' } }
        end

        attrs
      end

      def build_pipeline_commit_attributes
        attrs = []
        if pipeline_data.dig(:commit, :id)
          attrs << { key: 'pipeline.commit.id',
                     value: { stringValue: pipeline_data.dig(:commit, :id) } }
        end

        if pipeline_data.dig(:commit, :message)
          attrs << { key: 'pipeline.commit.message',
                     value: { stringValue: pipeline_data.dig(:commit, :message) } }
        end

        attrs
      end

      def build_pipeline_merge_request_attributes
        attrs = []
        if pipeline_data.dig(:merge_request, :id)
          attrs << { key: 'pipeline.merge_request.id',
                     value: { intValue: pipeline_data.dig(:merge_request, :id) } }
        end

        if pipeline_data.dig(:merge_request, :iid)
          attrs << { key: 'pipeline.merge_request.iid', value: { intValue: pipeline_data.dig(:merge_request, :iid) } }
        end

        attrs
      end

      def build_pipeline_source_pipeline_attributes
        attrs = []
        if pipeline_data.dig(:source_pipeline, :pipeline_id)
          attrs << { key: 'pipeline.source_pipeline.pipeline_id',
                value: { intValue: pipeline_data.dig(:source_pipeline, :pipeline_id) } }
        end

        attrs
      end

      def build_job_attributes(build)
        base_attributes = build_base_job_attributes(build)
        runner_attributes = build_runner_attributes(build)
        environment_attributes = build_environment_attributes(build)

        base_attributes + runner_attributes + environment_attributes
      end

      def build_base_job_attributes(build)
        base_attrs = [
          { key: 'job.id', value: { intValue: build[:id] } },
          { key: 'job.name', value: { stringValue: build[:name] } },
          { key: 'job.stage', value: { stringValue: build[:stage] } },
          { key: 'job.status', value: { stringValue: build[:status] } },
          { key: 'job.duration', value: { intValue: (build[:duration] || 0).to_i } },
          { key: 'job.queued_duration', value: { intValue: (build[:queued_duration] || 0).to_i } },
          { key: 'job.manual', value: { boolValue: build[:manual] || false } },
          { key: 'job.allow_failure', value: { boolValue: build[:allow_failure] || false } },
          { key: 'job.failure_reason', value: { stringValue: build[:failure_reason] || '' } }
        ]

        base_attrs + build_optional_job_attributes(build)
      end

      def build_optional_job_attributes(build)
        attrs = []
        attrs += build_timestamp_attributes(build)
        attrs += build_user_attributes(build)
        attrs += build_artifacts_attributes(build)
        attrs
      end

      def build_timestamp_attributes(build)
        attrs = []
        if build[:created_at].present?
          attrs << { key: 'job.created_at',
                     value: { intValue: time_to_nanoseconds(build[:created_at]) } }
        end

        attrs << { key: 'job.when', value: { stringValue: build[:when] || '' } } if build[:when].present?
        attrs
      end

      def build_user_attributes(build)
        attrs = []
        attrs << { key: 'job.user.id', value: { intValue: build.dig(:user, :id) } } if build.dig(:user, :id)

        if build.dig(:user, :username)
          attrs << { key: 'job.user.username', value: { stringValue: build.dig(:user, :username) || '' } }
        end

        attrs
      end

      def build_artifacts_attributes(build)
        attrs = []
        if build.dig(:artifacts_file, :filename)
          attrs << { key: 'job.artifacts.filename',
                     value: { stringValue: build.dig(:artifacts_file, :filename) } }
        end

        if build.dig(:artifacts_file, :size)
          attrs << { key: 'job.artifacts.size',
                     value: { intValue: build.dig(:artifacts_file, :size) } }
        end

        attrs
      end

      def build_runner_attributes(build)
        return [] unless build[:runner]

        attrs = build_base_runner_attributes(build)
        attrs += build_optional_runner_attributes(build)

        attrs
      end

      def build_base_runner_attributes(build)
        [
          { key: 'job.runner.id', value: { intValue: build.dig(:runner, :id) } },
          { key: 'job.runner.description', value: { stringValue: build.dig(:runner, :description) || '' } },
          { key: 'job.runner.tags', value: { arrayValue: { values: build.dig(:runner, :tags)&.map do |tag|
            { stringValue: tag }
          end || [] } } }
        ]
      end

      def build_optional_runner_attributes(build)
        attrs = []

        attrs << build_runner_type_attribute(build) if runner_type_present?(build)
        attrs << build_runner_active_attribute(build) if runner_key_present?(build, :active)
        attrs << build_runner_is_shared_attribute(build) if runner_key_present?(build, :is_shared)

        attrs
      end

      def runner_type_present?(build)
        build.dig(:runner, :runner_type).present?
      end

      def runner_key_present?(build, key)
        build.key?(:runner) && build[:runner].key?(key)
      end

      def build_runner_type_attribute(build)
        { key: 'job.runner.type', value: { stringValue: build.dig(:runner, :runner_type) || '' } }
      end

      def build_runner_active_attribute(build)
        { key: 'job.runner.active', value: { boolValue: build.dig(:runner, :active) || false } }
      end

      def build_runner_is_shared_attribute(build)
        { key: 'job.runner.is_shared', value: { boolValue: build.dig(:runner, :is_shared) || false } }
      end

      def build_environment_attributes(build)
        return [] unless build[:environment]

        attrs = [
          { key: 'job.environment.name', value: { stringValue: build.dig(:environment, :name) || '' } },
          { key: 'job.environment.action', value: { stringValue: build.dig(:environment, :action) || '' } }
        ]

        if build.dig(:environment, :deployment_tier)
          attrs << { key: 'job.environment.deployment_tier',
                     value: { stringValue: build.dig(:environment, :deployment_tier) } }
        end

        attrs
      end

      def service_name
        integration.service_name.presence || pipeline_data.dig(:project, :name) || 'gitlab-ci'
      end

      def environment
        integration.environment.presence || 'production'
      end

      def time_to_nanoseconds(active_support_time_value)
        return 0 if active_support_time_value.blank?
        return 0 unless active_support_time_value.is_a?(ActiveSupport::TimeWithZone)

        (active_support_time_value.utc.to_f * 1_000_000_000).to_i
      end

      def pipeline_trace_id
        SecureRandom.hex(16)
      end
      strong_memoize_attr :pipeline_trace_id

      def pipeline_span_id
        generate_span_id
      end
      strong_memoize_attr :pipeline_span_id

      def generate_span_id
        SecureRandom.hex(8)
      end
    end
  end
end
