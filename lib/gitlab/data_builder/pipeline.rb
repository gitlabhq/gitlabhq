# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Pipeline
      extend self

      def build(pipeline)
        {
          object_kind: 'pipeline',
          object_attributes: hook_attrs(pipeline),
          merge_request: pipeline.merge_request && merge_request_attrs(pipeline.merge_request),
          user: pipeline.user.try(:hook_attrs),
          project: pipeline.project.hook_attrs(backward: false),
          commit: pipeline.commit.try(:hook_attrs),
          builds: pipeline.builds.latest.map(&method(:build_hook_attrs))
        }
      end

      def hook_attrs(pipeline)
        {
          id: pipeline.id,
          ref: pipeline.source_ref,
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
          variables: pipeline.variables.map(&:hook_attrs)
        }
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
          url: Gitlab::UrlBuilder.build(merge_request)
        }
      end

      def build_hook_attrs(build)
        {
          id: build.id,
          stage: build.stage,
          name: build.name,
          status: build.status,
          created_at: build.created_at,
          started_at: build.started_at,
          finished_at: build.finished_at,
          duration: build.duration,
          queued_duration: build.queued_duration,
          when: build.when,
          manual: build.action?,
          allow_failure: build.allow_failure,
          user: build.user.try(:hook_attrs),
          runner: build.runner && runner_hook_attrs(build.runner),
          artifacts_file: {
            filename: build.artifacts_file&.filename,
            size: build.artifacts_size
          },
          environment: environment_hook_attrs(build)
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
        return unless build.has_environment?

        {
          name: build.expanded_environment_name,
          action: build.environment_action
        }
      end
    end
  end
end
