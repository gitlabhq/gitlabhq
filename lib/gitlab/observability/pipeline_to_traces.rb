# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineToTraces
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Observability::CicdSemconv

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
          attributes: compact_attributes(resource_legacy_attributes + resource_semconv_attributes)
        }
      end

      def resource_legacy_attributes
        [
          { key: 'service.name', value: { stringValue: service_name } },
          { key: 'service.version', value: { stringValue: '1.0.0' } },
          { key: 'deployment.environment', value: { stringValue: environment } },
          { key: 'gitlab.project.id', value: { intValue: pipeline_data.dig(:project, :id) } },
          { key: 'gitlab.project.name', value: { stringValue: pipeline_data.dig(:project, :name) } },
          { key: 'gitlab.project.path',
            value: { stringValue: pipeline_data.dig(:project, :path_with_namespace) } },
          { key: 'gitlab.pipeline.id', value: { intValue: pipeline[:id] } },
          { key: 'gitlab.pipeline.ref', value: { stringValue: pipeline[:ref] } },
          { key: 'gitlab.pipeline.source', value: { stringValue: pipeline[:source] } }
        ]
      end

      def resource_semconv_attributes
        [
          { key: 'cicd.pipeline.run.id', value: { stringValue: pipeline[:id].to_s } },
          { key: 'cicd.pipeline.run.url.full', value: { stringValue: pipeline[:url] || '' } },
          { key: 'cicd.pipeline.name', value: { stringValue: pipeline[:name] || '' } },
          { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
          { key: 'vcs.repository.name', value: { stringValue: pipeline_data.dig(:project, :name) || '' } },
          { key: 'vcs.owner.name', value: { stringValue: vcs_owner_name } },
          { key: 'vcs.repository.url.full', value: { stringValue: pipeline_data.dig(:project, :web_url) || '' } },
          { key: 'vcs.ref.head.name', value: { stringValue: pipeline[:ref] || '' } },
          { key: 'vcs.ref.head.revision', value: { stringValue: pipeline[:sha] || '' } },
          { key: 'vcs.ref.head.type', value: { stringValue: pipeline[:tag] ? 'tag' : 'branch' } }
        ]
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
        compact_attributes(
          pipeline_legacy_attributes + pipeline_semconv_attributes
        ) + build_optional_pipeline_attributes
      end

      def pipeline_legacy_attributes
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

      def pipeline_semconv_attributes
        [
          { key: 'cicd.pipeline.name', value: { stringValue: pipeline[:name] || '' } },
          { key: 'cicd.pipeline.result', value: { stringValue: map_pipeline_result(pipeline[:status]) || '' } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: map_pipeline_run_state(pipeline[:status]) || '' } },
          { key: 'cicd.pipeline.trigger.type',
            value: { stringValue: map_pipeline_trigger_type(pipeline[:source]) || '' } },
          { key: 'cicd.pipeline.run.queue_duration', value: { intValue: (pipeline[:queued_duration] || 0).to_i } },
          { key: 'vcs.ref.head.protected', value: { boolValue: pipeline[:protected_ref] || false } }
        ]
      end

      def build_optional_pipeline_attributes
        attrs = []
        attrs += build_pipeline_specific_attributes
        attrs += build_vcs_ref_attributes
        attrs += build_pipeline_user_attributes
        attrs += build_pipeline_commit_attributes
        attrs += build_merge_request_vcs_attributes
        attrs += build_pipeline_source_pipeline_attributes
        attrs
      end

      def build_pipeline_specific_attributes
        attrs = []
        attrs << { key: 'gitlab.cicd.pipeline.iid', value: { intValue: pipeline[:iid] } } if pipeline[:iid]
        attrs << { key: 'pipeline.tag', value: { boolValue: pipeline[:tag] || false } } if pipeline.key?(:tag)

        if pipeline[:before_sha].present?
          attrs << { key: 'pipeline.before_sha', value: { stringValue: pipeline[:before_sha] } }
        end

        if pipeline[:stages].present?
          stages_values = pipeline[:stages].map { |stage| { stringValue: stage } }
          attrs << { key: 'pipeline.stages', value: { arrayValue: { values: stages_values } } }
          attrs << { key: 'gitlab.cicd.pipeline.stages', value: { arrayValue: { values: stages_values } } }
        end

        attrs
      end

      def build_vcs_ref_attributes
        attrs = []
        attrs << { key: 'vcs.ref.head.name', value: { stringValue: pipeline[:ref] } } if pipeline[:ref].present?
        attrs << { key: 'vcs.ref.head.revision', value: { stringValue: pipeline[:sha] } } if pipeline[:sha].present?

        if pipeline[:before_sha].present?
          attrs << { key: 'vcs.ref.base.revision', value: { stringValue: pipeline[:before_sha] } }
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
          attrs << { key: 'pipeline.commit.id', value: { stringValue: pipeline_data.dig(:commit, :id) } }
        end

        if pipeline_data.dig(:commit, :message)
          attrs << { key: 'pipeline.commit.message', value: { stringValue: pipeline_data.dig(:commit, :message) } }
        end

        attrs
      end

      def build_merge_request_vcs_attributes
        return [] unless pipeline_data.dig(:merge_request, :iid)

        mr = pipeline_data[:merge_request]
        state = map_mr_state(mr[:state])

        compact_attributes([
          { key: 'pipeline.merge_request.id', value: { intValue: mr[:id] } },
          { key: 'pipeline.merge_request.iid', value: { intValue: mr[:iid] } },
          { key: 'vcs.change.id', value: { stringValue: mr[:iid].to_s } },
          { key: 'vcs.change.title', value: { stringValue: mr[:title] || '' } },
          { key: 'vcs.change.state', value: { stringValue: state || '' } },
          { key: 'vcs.ref.head.name', value: { stringValue: mr[:source_branch] || '' } },
          { key: 'vcs.ref.base.name', value: { stringValue: mr[:target_branch] || '' } }
        ])
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
        compact_attributes(job_legacy_attributes(build) + job_semconv_attributes(build)) +
          build_runner_attributes(build) + build_environment_attributes(build) +
          build_optional_job_attributes(build)
      end

      def job_legacy_attributes(build)
        [
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
      end

      def job_semconv_attributes(build)
        [
          { key: 'cicd.pipeline.task.name', value: { stringValue: build[:name] } },
          { key: 'cicd.pipeline.task.run.id', value: { stringValue: build[:id].to_s } },
          { key: 'cicd.pipeline.task.run.result', value: { stringValue: map_task_run_result(build[:status]) || '' } },
          { key: 'cicd.pipeline.task.run.state', value: { stringValue: map_task_run_state(build[:status]) || '' } },
          { key: 'cicd.pipeline.task.type', value: { stringValue: map_pipeline_task_type(build[:stage]) || '' } },
          { key: 'cicd.pipeline.task.allow_failure', value: { boolValue: build[:allow_failure] || false } },
          { key: 'cicd.pipeline.task.run.failure_reason', value: { stringValue: build[:failure_reason] || '' } },
          { key: 'cicd.pipeline.task.trigger.type',
            value: { stringValue: build[:manual] ? 'manual' : 'automatic' } },
          { key: 'cicd.pipeline.task.run.queue_duration', value: { intValue: (build[:queued_duration] || 0).to_i } }
        ]
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
          attrs << { key: 'job.created_at', value: { intValue: time_to_nanoseconds(build[:created_at]) } }
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
          attrs << { key: 'job.artifacts.filename', value: { stringValue: build.dig(:artifacts_file, :filename) } }
        end

        if build.dig(:artifacts_file, :size)
          attrs << { key: 'job.artifacts.size', value: { intValue: build.dig(:artifacts_file, :size) } }
        end

        attrs
      end

      def build_runner_attributes(build)
        return [] unless build[:runner]

        compact_attributes(runner_legacy_attributes(build) + runner_semconv_attributes(build)) +
          build_optional_runner_attributes(build)
      end

      def runner_legacy_attributes(build)
        [
          { key: 'job.runner.id', value: { intValue: build.dig(:runner, :id) } },
          { key: 'job.runner.description', value: { stringValue: build.dig(:runner, :description) || '' } },
          { key: 'job.runner.tags', value: { arrayValue: { values: build.dig(:runner, :tags)&.map do |tag|
            { stringValue: tag }
          end || [] } } }
        ]
      end

      def runner_semconv_attributes(build)
        [
          { key: 'cicd.worker.id', value: { stringValue: build.dig(:runner, :id).to_s } },
          { key: 'cicd.worker.name', value: { stringValue: build.dig(:runner, :description) || '' } },
          { key: 'cicd.worker.state', value: { stringValue: map_worker_state(build.dig(:runner, :active)) } },
          { key: 'cicd.worker.tags', value: { arrayValue: { values: build.dig(:runner, :tags)&.map do |tag|
            { stringValue: tag }
          end || [] } } }
        ]
      end

      def build_optional_runner_attributes(build)
        attrs = []

        attrs << build_runner_type_attribute(build) if runner_type_present?(build)
        attrs << build_runner_worker_type_attribute(build) if runner_type_present?(build)
        attrs << build_runner_active_attribute(build) if runner_key_present?(build, :active)
        attrs.concat(build_runner_is_shared_attributes(build)) if runner_key_present?(build, :is_shared)

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

      def build_runner_worker_type_attribute(build)
        { key: 'cicd.worker.type', value: { stringValue: build.dig(:runner, :runner_type) || '' } }
      end

      def build_runner_active_attribute(build)
        { key: 'job.runner.active', value: { boolValue: build.dig(:runner, :active) || false } }
      end

      def build_runner_is_shared_attributes(build)
        [
          { key: 'job.runner.is_shared', value: { boolValue: build.dig(:runner, :is_shared) || false } },
          { key: 'gitlab.cicd.runner.is_shared', value: { boolValue: build.dig(:runner, :is_shared) || false } }
        ]
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

      def vcs_owner_name
        path = pipeline_data.dig(:project, :path_with_namespace) || ''
        parts = path.split('/')
        return '' if parts.length <= 1

        parts[0..-2].join('/')
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
