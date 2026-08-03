# frozen_string_literal: true

module Gitlab
  module Observability
    class PipelineConverterBase
      include Gitlab::Utils::StrongMemoize
      include Gitlab::Observability::CicdSemconv
      include Gitlab::Observability::TracingHelpers

      def initialize(integration, pipeline_data)
        @integration = integration
        @pipeline_data = pipeline_data
        @pipeline = pipeline_data[:object_attributes]
        @builds = (pipeline_data[:builds] || []) + (pipeline_data[:bridges] || [])
      end

      private

      attr_reader :integration, :pipeline_data, :pipeline, :builds

      def service_name
        integration.service_name.presence || pipeline_data.dig(:project, :name) || 'gitlab-ci'
      end

      def environment
        integration.environment.presence || 'production'
      end

      def resource_semconv
        [
          { key: 'deployment.environment', value: { stringValue: environment } },
          { key: 'service.name', value: { stringValue: service_name } },
          { key: 'service.version', value: { stringValue: Gitlab::VERSION } },
          { key: 'vcs.owner.name', value: { stringValue: vcs_owner_name } },
          { key: 'vcs.provider.name', value: { stringValue: 'gitlab' } },
          { key: 'vcs.repository.name', value: { stringValue: pipeline_data.dig(:project, :name) || '' } },
          { key: 'gitlab.vcs.repository.id', value: { stringValue: pipeline_data.dig(:project, :id).to_s } },
          { key: 'vcs.repository.url.full', value: { stringValue: pipeline_data.dig(:project, :web_url) || '' } }
        ]
      end

      def job_legacy_attributes(build)
        (job_legacy_core_attributes(build) +
          job_legacy_artifacts_attributes(build) +
          job_legacy_environment_attributes(build) +
          job_legacy_user_attributes(build) +
          job_legacy_runner_attributes(build)).compact
      end

      def job_legacy_core_attributes(build)
        [
          { key: 'job.allow_failure', value: { boolValue: build[:allow_failure] || false } },
          (build[:created_at].present? &&
            { key: 'job.created_at', value: { intValue: time_to_nanoseconds(build[:created_at]) } }) || nil,
          { key: 'job.duration', value: { intValue: (build[:duration] || 0).to_i } },
          { key: 'job.failure_reason', value: { stringValue: build[:failure_reason] || '' } },
          build[:id] && { key: 'job.id', value: { intValue: build[:id] } },
          { key: 'job.manual', value: { boolValue: build[:manual] || false } },
          { key: 'job.name', value: { stringValue: build[:name] } },
          { key: 'job.queued_duration', value: { intValue: (build[:queued_duration] || 0).to_i } },
          { key: 'job.stage', value: { stringValue: build[:stage] } },
          { key: 'job.status', value: { stringValue: build[:status] } },
          (build[:bridge] &&
            { key: 'job.type', value: { stringValue: 'bridge' } }) || nil,
          (build[:when].present? &&
            { key: 'job.when', value: { stringValue: build[:when] } }) || nil
        ]
      end

      def job_legacy_artifacts_attributes(build)
        return [] unless build[:artifacts_file]

        [
          (build.dig(:artifacts_file, :filename) &&
            { key: 'job.artifacts.filename',
              value: { stringValue: build.dig(:artifacts_file, :filename) } }) || nil,
          (build.dig(:artifacts_file, :size) &&
            { key: 'job.artifacts.size', value: { intValue: build.dig(:artifacts_file, :size) } }) || nil
        ]
      end

      def job_legacy_environment_attributes(build)
        return [] unless build[:environment]

        [
          { key: 'job.environment.action', value: { stringValue: build.dig(:environment, :action) || '' } },
          (build.dig(:environment, :deployment_tier) &&
            { key: 'job.environment.deployment_tier',
              value: { stringValue: build.dig(:environment, :deployment_tier) } }) || nil,
          { key: 'job.environment.name', value: { stringValue: build.dig(:environment, :name) || '' } }
        ]
      end

      def job_legacy_user_attributes(build)
        [
          (build.dig(:user, :id) &&
            { key: 'job.user.id', value: { intValue: build.dig(:user, :id) } }) || nil,
          (build.dig(:user, :username) &&
            { key: 'job.user.username', value: { stringValue: build.dig(:user, :username) } }) || nil
        ]
      end

      def job_legacy_runner_attributes(build)
        runner = build[:runner]
        return [] unless runner

        tag_values = (runner[:tags] || []).map do |tag|
          { stringValue: tag }
        end

        [
          (runner.key?(:active) &&
            { key: 'job.runner.active', value: { boolValue: runner[:active] || false } }) || nil,
          { key: 'job.runner.description', value: { stringValue: runner[:description] || '' } },
          (runner[:id] && { key: 'job.runner.id', value: { intValue: runner[:id] } }) || nil,
          (runner.key?(:is_shared) &&
            { key: 'job.runner.is_shared', value: { boolValue: runner[:is_shared] || false } }) || nil,
          { key: 'job.runner.tags', value: { arrayValue: { values: tag_values } } }
        ] + job_legacy_runner_type_attribute(runner)
      end

      def job_legacy_runner_type_attribute(runner)
        return [] unless runner[:runner_type].present?

        [{ key: 'job.runner.type', value: { stringValue: runner[:runner_type] } }]
      end

      def pipeline_legacy_attributes
        (pipeline_legacy_core_attributes +
          pipeline_legacy_optional_attributes +
          pipeline_legacy_commit_attributes +
          pipeline_legacy_merge_request_attributes +
          pipeline_legacy_user_attributes).compact
      end

      def pipeline_legacy_core_attributes
        [
          { key: 'pipeline.detailed_status', value: { stringValue: pipeline[:detailed_status] || '' } },
          { key: 'pipeline.duration', value: { intValue: (pipeline[:duration] || 0).to_i } },
          pipeline[:id] && { key: 'pipeline.id', value: { intValue: pipeline[:id] } },
          pipeline[:iid] && { key: 'pipeline.iid', value: { intValue: pipeline[:iid] } },
          { key: 'pipeline.name', value: { stringValue: pipeline[:name] || '' } },
          { key: 'pipeline.protected_ref', value: { boolValue: pipeline[:protected_ref] || false } },
          { key: 'pipeline.queued_duration', value: { intValue: (pipeline[:queued_duration] || 0).to_i } },
          { key: 'pipeline.ref', value: { stringValue: pipeline[:ref] } },
          { key: 'pipeline.sha', value: { stringValue: pipeline[:sha] } },
          { key: 'pipeline.status', value: { stringValue: pipeline[:status] } },
          { key: 'pipeline.url', value: { stringValue: pipeline[:url] || '' } }
        ]
      end

      def pipeline_legacy_optional_attributes
        [
          (pipeline[:before_sha].present? &&
            { key: 'pipeline.before_sha', value: { stringValue: pipeline[:before_sha] } }) || nil,
          (pipeline_data.dig(:source_pipeline, :pipeline_id) &&
            { key: 'pipeline.source_pipeline.pipeline_id',
              value: { intValue: pipeline_data.dig(:source_pipeline, :pipeline_id) } }) || nil,
          (pipeline[:stages].present? &&
            { key: 'pipeline.stages',
              value: { arrayValue: { values: pipeline[:stages].map { |s| { stringValue: s } } } } }) || nil,
          (pipeline.key?(:tag) &&
            { key: 'pipeline.tag', value: { boolValue: pipeline[:tag] || false } }) || nil
        ]
      end

      def pipeline_legacy_commit_attributes
        [
          (pipeline_data.dig(:commit, :id) &&
            { key: 'pipeline.commit.id', value: { stringValue: pipeline_data.dig(:commit, :id) } }) || nil,
          (pipeline_data.dig(:commit, :message) &&
            { key: 'pipeline.commit.message',
              value: { stringValue: pipeline_data.dig(:commit, :message) } }) || nil
        ]
      end

      def pipeline_legacy_merge_request_attributes
        [
          (pipeline_data.dig(:merge_request, :id) &&
            { key: 'pipeline.merge_request.id',
              value: { intValue: pipeline_data.dig(:merge_request, :id) } }) || nil,
          (pipeline_data.dig(:merge_request, :iid) &&
            { key: 'pipeline.merge_request.iid',
              value: { intValue: pipeline_data.dig(:merge_request, :iid) } }) || nil
        ]
      end

      def pipeline_legacy_user_attributes
        [
          (pipeline_data.dig(:user, :id) &&
            { key: 'pipeline.user.id', value: { intValue: pipeline_data.dig(:user, :id) } }) || nil,
          (pipeline_data.dig(:user, :username) &&
            { key: 'pipeline.user.username',
              value: { stringValue: pipeline_data.dig(:user, :username) } }) || nil
        ]
      end

      def pipeline_semconv_attributes
        (pipeline_semconv_cicd_attributes +
          pipeline_semconv_vcs_attributes +
          pipeline_semconv_change_attributes +
          pipeline_semconv_gitlab_attributes).compact
      end

      def pipeline_semconv_cicd_attributes
        [
          { key: 'cicd.pipeline.name', value: { stringValue: pipeline[:name].to_s } },
          { key: 'cicd.pipeline.result', value: { stringValue: map_pipeline_result(pipeline[:status]).to_s } },
          { key: 'cicd.pipeline.run.id', value: { stringValue: pipeline[:id].to_s } },
          { key: 'cicd.pipeline.run.state', value: { stringValue: map_pipeline_run_state(pipeline[:status]).to_s } },
          { key: 'cicd.pipeline.run.url.full', value: { stringValue: pipeline[:url].to_s } }
        ]
      end

      def pipeline_semconv_vcs_attributes
        [
          (pipeline[:before_sha].present? &&
            { key: 'vcs.ref.base.revision', value: { stringValue: pipeline[:before_sha] } }) || nil,
          { key: 'vcs.ref.head.name', value: { stringValue: pipeline[:ref].to_s } },
          { key: 'vcs.ref.head.revision', value: { stringValue: pipeline[:sha].to_s } },
          { key: 'vcs.ref.head.type', value: { stringValue: pipeline[:tag] ? 'tag' : 'branch' } }
        ]
      end

      def pipeline_semconv_change_attributes
        [
          (pipeline_data.dig(:merge_request, :id) &&
            { key: 'vcs.change.id', value: { stringValue: pipeline_data.dig(:merge_request, :id).to_s } }) || nil,
          (pipeline_data.dig(:merge_request, :state) &&
            { key: 'vcs.change.state',
              value: { stringValue: map_mr_state(pipeline_data.dig(:merge_request, :state)).to_s } }) || nil,
          (pipeline_data.dig(:merge_request, :title) &&
            { key: 'vcs.change.title',
              value: { stringValue: pipeline_data.dig(:merge_request, :title) } }) || nil,
          (pipeline_data.dig(:merge_request, :target_branch) &&
            { key: 'vcs.ref.base.name',
              value: { stringValue: pipeline_data.dig(:merge_request, :target_branch) } }) || nil
        ]
      end

      def pipeline_semconv_gitlab_attributes
        [
          (pipeline_data.dig(:commit, :message) &&
            { key: 'gitlab.vcs.ref.head.revision.message',
              value: { stringValue: pipeline_data.dig(:commit, :message) } }) || nil,
          { key: 'gitlab.cicd.pipeline.run.duration', value: { intValue: pipeline[:duration].to_i } },
          { key: 'gitlab.cicd.pipeline.run.queued_duration',
            value: { intValue: pipeline[:queued_duration].to_i } },
          (pipeline_data.dig(:source_pipeline, :pipeline_id) &&
            { key: 'gitlab.cicd.pipeline.source_pipeline.id',
              value: { intValue: pipeline_data.dig(:source_pipeline, :pipeline_id) } }) || nil,
          (pipeline[:stages].present? &&
            { key: 'gitlab.cicd.pipeline.stages',
              value: { arrayValue: { values: pipeline[:stages].map { |s| { stringValue: s } } } } }) || nil,
          { key: 'gitlab.cicd.pipeline.trigger.type',
            value: { stringValue: pipeline[:source].to_s } },
          (pipeline_data.dig(:user, :id) &&
            { key: 'gitlab.cicd.pipeline.user.id',
              value: { intValue: pipeline_data.dig(:user, :id) } }) || nil,
          (pipeline_data.dig(:user, :username) &&
            { key: 'gitlab.cicd.pipeline.user.username',
              value: { stringValue: pipeline_data.dig(:user, :username) } }) || nil,
          { key: 'gitlab.vcs.ref.head.protected', value: { boolValue: !!pipeline[:protected_ref] } }
        ]
      end

      def job_semconv_attributes(build)
        (job_semconv_cicd_attributes(build) +
          job_semconv_gitlab_attributes(build) +
          job_semconv_runner_attributes(build)).compact
      end

      def job_semconv_cicd_attributes(build)
        [
          { key: 'cicd.pipeline.task.name', value: { stringValue: build[:name] } },
          { key: 'cicd.pipeline.task.run.id', value: { stringValue: build[:id].to_s } },
          { key: 'cicd.pipeline.task.run.result', value: { stringValue: map_task_run_result(build[:status]) || '' } },
          { key: 'cicd.pipeline.task.run.state', value: { stringValue: map_task_run_state(build[:status]) || '' } },
          { key: 'cicd.pipeline.task.run.url.full', value: { stringValue: job_url(build) } },
          { key: 'cicd.pipeline.task.type', value: { stringValue: build[:stage].to_s } }
        ]
      end

      def job_semconv_gitlab_attributes(build)
        job_semconv_gitlab_core_attributes(build) +
          job_semconv_gitlab_artifacts_attributes(build) +
          job_semconv_gitlab_environment_attributes(build) +
          job_semconv_gitlab_user_attributes(build)
      end

      def job_semconv_gitlab_core_attributes(build)
        [
          { key: 'gitlab.cicd.pipeline.task.allow_failure', value: { boolValue: build[:allow_failure] || false } },
          (build[:bridge] &&
            { key: 'gitlab.cicd.pipeline.task.kind', value: { stringValue: 'bridge' } }) || nil,
          (build[:created_at].present? &&
            { key: 'gitlab.cicd.pipeline.task.run.created_at',
              value: { intValue: time_to_nanoseconds(build[:created_at]) } }) || nil,
          { key: 'gitlab.cicd.pipeline.task.run.duration', value: { intValue: (build[:duration] || 0).to_i } },
          { key: 'gitlab.cicd.pipeline.task.run.failure_reason',
            value: { stringValue: build[:failure_reason] || '' } },
          { key: 'gitlab.cicd.pipeline.task.run.queued_duration',
            value: { intValue: (build[:queued_duration] || 0).to_i } },
          (build[:when].present? &&
            { key: 'gitlab.cicd.pipeline.task.run.when',
              value: { stringValue: build[:when] } }) || nil,
          { key: 'gitlab.cicd.pipeline.task.trigger.type',
            value: { stringValue: pipeline[:source].to_s } }
        ]
      end

      def job_semconv_gitlab_artifacts_attributes(build)
        return [] unless build[:artifacts_file]

        [
          (build.dig(:artifacts_file, :filename) &&
            { key: 'gitlab.cicd.pipeline.task.artifacts.filename',
              value: { stringValue: build.dig(:artifacts_file, :filename) } }) || nil,
          (build.dig(:artifacts_file, :size) &&
            { key: 'gitlab.cicd.pipeline.task.artifacts.size',
              value: { intValue: build.dig(:artifacts_file, :size) } }) || nil
        ]
      end

      def job_semconv_gitlab_environment_attributes(build)
        return [] unless build[:environment]

        [
          { key: 'gitlab.cicd.pipeline.task.environment.action',
            value: { stringValue: build.dig(:environment, :action) || '' } },
          (build.dig(:environment, :deployment_tier) &&
            { key: 'gitlab.cicd.pipeline.task.environment.deployment_tier',
              value: { stringValue: build.dig(:environment, :deployment_tier) } }) || nil,
          { key: 'gitlab.cicd.pipeline.task.environment.name',
            value: { stringValue: build.dig(:environment, :name) || '' } }
        ]
      end

      def job_semconv_gitlab_user_attributes(build)
        [
          (build.dig(:user, :id) &&
            { key: 'gitlab.cicd.pipeline.task.user.id',
              value: { intValue: build.dig(:user, :id) } }) || nil,
          (build.dig(:user, :username) &&
            { key: 'gitlab.cicd.pipeline.task.user.username',
              value: { stringValue: build.dig(:user, :username) } }) || nil
        ]
      end

      def job_semconv_runner_attributes(build)
        runner = build[:runner]
        return [] unless runner

        tag_values = (runner[:tags] || []).map do |tag|
          { stringValue: tag }
        end

        [
          (runner[:id] &&
            { key: 'cicd.worker.id', value: { stringValue: runner[:id].to_s } }) || nil,
          { key: 'cicd.worker.name', value: { stringValue: runner[:description] || '' } },
          { key: 'cicd.worker.state', value: { stringValue: map_worker_state(runner[:active]) } },
          (runner.key?(:is_shared) &&
            { key: 'gitlab.cicd.runner.is_shared', value: { boolValue: runner[:is_shared] || false } }) || nil,
          { key: 'gitlab.cicd.worker.tags', value: { arrayValue: { values: tag_values } } },
          (runner[:runner_type].present? &&
            { key: 'gitlab.cicd.worker.type', value: { stringValue: runner[:runner_type] } }) || nil
        ]
      end

      def vcs_owner_name
        path = pipeline_data.dig(:project, :path_with_namespace) || ''
        parts = path.split('/')
        return '' if parts.length <= 1

        parts[0..-2].join('/')
      end

      def job_url(build)
        project_url = pipeline_data.dig(:project, :web_url)
        return '' unless project_url && build[:id]

        "#{project_url}/-/jobs/#{build[:id]}"
      end

      def time_to_nanoseconds(value)
        return 0 if value.blank?
        return 0 unless value.is_a?(ActiveSupport::TimeWithZone)

        (value.utc.to_f * 1_000_000_000).to_i
      end

      def exported_span_id(build)
        return Gitlab::Ci::TraceContext.span_id_for_bridge(build[:id]) if build[:bridge]

        job_span_id(build)
      end
    end
  end
end
