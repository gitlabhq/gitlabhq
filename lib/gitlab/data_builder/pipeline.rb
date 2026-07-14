# frozen_string_literal: true

module Gitlab
  module DataBuilder
    # Some callers want to include retried builds, so we wrap the payload hash
    # in a SimpleDelegator with additional methods.
    class Pipeline < SimpleDelegator
      def self.build(pipeline)
        new(pipeline)
      end

      def initialize(pipeline)
        @pipeline = pipeline

        trace_correlation_enabled = trace_correlation_enabled?(pipeline)

        attrs = {
          object_kind: 'pipeline',
          object_attributes: hook_attrs(pipeline),
          merge_request: pipeline.merge_request && merge_request_attrs(pipeline.merge_request),
          user: pipeline.user.try(:hook_attrs),
          project: pipeline.project.hook_attrs(backward: false),
          commit: pipeline.commit.try(:hook_attrs),
          builds: Gitlab::Lazy.new do
            preload_builds(pipeline, :latest_builds)
            pipeline.latest_builds.map { |build| build_hook_attrs(build) }
          end
        }

        if trace_correlation_enabled
          attrs[:object_attributes][:root_pipeline_id] = pipeline.root_ancestor.id
          attrs[:bridges] = Gitlab::Lazy.new do
            preload_bridges(pipeline, :latest_bridges)
            pipeline.latest_bridges.map { |bridge| build_hook_attrs(bridge, skip_artifacts: true).merge(bridge: true) }
          end
        end

        if pipeline.source_pipeline.present?
          if trace_correlation_enabled
            ActiveRecord::Associations::Preloader.new(
              records: [pipeline.source_pipeline],
              associations: :source_bridge
            ).call
          end

          attrs[:source_pipeline] =
            source_pipeline_attrs(pipeline.source_pipeline, trace_correlation_enabled)
        end

        super(attrs)
      end

      def with_retried_builds
        merge(
          builds: Gitlab::Lazy.new do
            preload_builds(@pipeline, :builds)
            @pipeline.builds.map { |build| build_hook_attrs(build) }
          end
        )
      end

      private

      def trace_correlation_enabled?(pipeline)
        Feature.enabled?(:ci_pipeline_otlp_trace_correlation, pipeline.project)
      end

      # Unlike preload_builds, this omits runner: :tags and
      # job_artifacts_archive: []. Ci::Bridge overrides #runner to return nil,
      # and bridges are serialized with skip_artifacts: true, so build_hook_attrs
      # never triggers those queries for bridges.
      def preload_bridges(pipeline, association)
        ActiveRecord::Associations::Preloader.new(
          records: [pipeline],
          associations: {
            association => {
              **::Ci::Pipeline::PROJECT_ROUTE_AND_NAMESPACE_ROUTE,
              user: [],
              job_definition: [],
              ci_stage: []
            }
          }
        ).call
      end

      def preload_builds(pipeline, association)
        ActiveRecord::Associations::Preloader.new(
          records: [pipeline],
          associations: {
            association => {
              **::Ci::Pipeline::PROJECT_ROUTE_AND_NAMESPACE_ROUTE,
              runner: :tags,
              job_environment: [],
              job_artifacts_archive: [],
              user: [],
              job_definition: [],
              ci_stage: []
            }
          }
        ).call
      end

      def hook_attrs(pipeline)
        {
          id: pipeline.id,
          iid: pipeline.iid,
          name: pipeline.name,
          ref: pipeline.source_ref,
          ref_status_name: pipeline.ref_status_name,
          tag: pipeline.tag,
          sha: pipeline.sha,
          before_sha: pipeline.before_sha,
          source: pipeline.source,
          status: pipeline.status,
          detailed_status: pipeline.detailed_status(nil).label,
          stages: pipeline.stages_names,
          created_at: pipeline.created_at,
          finished_at: pipeline.finished_at,
          duration: pipeline.duration,
          queued_duration: pipeline.queued_duration,
          protected_ref: pipeline.protected_ref?,
          variables: pipeline.variables.map(&:hook_attrs),
          url: Gitlab::Routing.url_helpers.project_pipeline_url(pipeline.project, pipeline)
        }
      end

      def source_pipeline_attrs(source_pipeline, trace_correlation_enabled = false)
        project = source_pipeline.source_project

        attrs = {
          project: {
            id: project.id,
            web_url: project.web_url,
            path_with_namespace: project.full_path
          },
          job_id: source_pipeline.source_job_id,
          pipeline_id: source_pipeline.source_pipeline_id
        }

        attrs[:bridge_id] = source_pipeline.source_bridge&.id if trace_correlation_enabled

        attrs
      end

      def merge_request_attrs(merge_request)
        {
          id: merge_request.id,
          iid: merge_request.iid,
          title: merge_request.title,
          source_branch: merge_request.source_branch,
          source_project_id: merge_request.source_project_id,
          target_branch: merge_request.target_branch,
          target_project_id: merge_request.target_project_id,
          state: merge_request.state,
          merge_status: merge_request.public_merge_status,
          detailed_merge_status: detailed_merge_status(merge_request),
          url: Gitlab::UrlBuilder.build(merge_request)
        }
      end

      def build_hook_attrs(build, skip_artifacts: false)
        {
          id: build.id,
          stage: build.stage_name,
          name: build.name,
          status: build.status,
          created_at: build.created_at,
          started_at: build.started_at,
          finished_at: build.finished_at,
          duration: build.duration,
          queued_duration: build.queued_duration,
          failure_reason: (build.failure_reason if build.failed?),
          when: build.when,
          manual: build.action?,
          allow_failure: build.allow_failure,
          user: build.user.try(:hook_attrs),
          runner: build.runner && runner_hook_attrs(build.runner),
          **artifacts_file_hook_attrs(build, skip_artifacts),
          environment: environment_hook_attrs(build)
        }
      end

      def artifacts_file_hook_attrs(build, skip_artifacts)
        return {} if skip_artifacts

        {
          artifacts_file: {
            filename: build.artifacts_file&.filename,
            size: build.artifacts_size
          }
        }
      end

      def runner_hook_attrs(runner)
        {
          id: runner.id,
          description: runner.description,
          runner_type: runner.runner_type,
          active: runner.active?,
          is_shared: runner.instance_type?,
          tags: runner.tags&.map(&:name)
        }
      end

      def environment_hook_attrs(build)
        return unless build.has_environment_keyword?

        {
          name: build.expanded_environment_name,
          action: build.environment_action,
          deployment_tier: build.persisted_environment.try(:tier)
        }
      end

      def detailed_merge_status(merge_request)
        ::MergeRequests::Mergeability::DetailedMergeStatusService.new(merge_request: merge_request).execute.to_s
      end
    end
  end
end

Gitlab::DataBuilder::Pipeline.prepend_mod
