# frozen_string_literal: true

module Gitlab
  module DataBuilder
    module Build
      extend self

      def build(build)
        project = build.project
        commit = build.pipeline
        user = build.user

        author_url = build_author_url(build.commit, commit)

        attrs = {
          object_kind: 'build',

          ref: build.ref,
          tag: build.tag,
          before_sha: build.before_sha,
          sha: build.sha,
          retries_count: build.retries_count,

          # TODO: should this be not prefixed with build_?
          # Leaving this way to have backward compatibility
          build_id: build.id,
          build_name: build.name,
          build_stage: build.stage_name,
          build_status: build.status,
          build_created_at: build.created_at,
          build_started_at: build.started_at,
          build_finished_at: build.finished_at,
          build_duration: build.duration,
          build_queued_duration: build.queued_duration,
          build_allow_failure: build.allow_failure,
          build_failure_reason: build.failure_reason,
          pipeline_id: commit.id,
          runner: build_runner(build.runner),

          # TODO: do we still need it?
          project_id: project.id,
          project_name: project.full_name,

          user: user.try(:hook_attrs),

          commit: {
            # note: commit.id is actually the pipeline id
            id: commit.id,
            name: commit.name,
            sha: commit.sha,
            message: commit.git_commit_message,
            author_name: commit.git_author_name,
            author_email: commit.git_author_email,
            author_url: author_url,
            status: commit.status,
            duration: commit.duration,
            started_at: commit.started_at,
            finished_at: commit.finished_at
          },

          repository: {
            name: project.name,
            url: project.url_to_repo,
            description: project.description,
            homepage: project.web_url,
            git_http_url: project.http_url_to_repo,
            git_ssh_url: project.ssh_url_to_repo,
            visibility_level: project.visibility_level
          },

          project: project.hook_attrs(backward: false),

          environment: build_environment(build)
        }

        attrs[:source_pipeline] = source_pipeline_attrs(commit.source_pipeline) if commit.source_pipeline.present?
        attrs
      end

      private

      def build_author_url(commit, pipeline)
        author = commit.try(:author)
        author ? Gitlab::Routing.url_helpers.user_url(author) : "mailto:#{pipeline.git_author_email}"
      end

      def build_runner(runner)
        return unless runner

        {
          id: runner.id,
          description: runner.description,
          runner_type: runner.runner_type,
          active: runner.active?,
          is_shared: runner.instance_type?,
          tags: runner.tags&.map(&:name)
        }
      end

      def build_environment(build)
        return unless build.has_environment_keyword?

        {
          name: build.expanded_environment_name,
          action: build.environment_action
        }
      end

      def source_pipeline_attrs(source_pipeline)
        project = source_pipeline.source_project

        {
          project: {
            id: project.id,
            web_url: project.web_url,
            path_with_namespace: project.full_path
          },
          job_id: source_pipeline.source_job_id,
          pipeline_id: source_pipeline.source_pipeline_id
        }
      end
    end
  end
end
