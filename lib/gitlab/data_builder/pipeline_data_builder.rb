module Gitlab
  module DataBuilder
    module PipelineDataBuilder
      module_function

      def build(pipeline)
        {
          object_kind: 'pipeline',
          user: pipeline.user.try(:hook_attrs),
          project: pipeline.project.hook_attrs(backward: false),
          commit: pipeline.commit.try(:hook_attrs),
          object_attributes: hook_attrs(pipeline),
          builds: pipeline.builds.map(&method(:build_hook_attrs))
        }
      end

      def hook_attrs(pipeline)
        first_pending_build = pipeline.builds.first_pending
        config_processor = pipeline.config_processor

        {
          id: pipeline.id,
          ref: pipeline.ref,
          tag: pipeline.tag,
          sha: pipeline.sha,
          before_sha: pipeline.before_sha,
          status: pipeline.status,
          stage: first_pending_build.try(:stage),
          stages: config_processor.try(:stages),
          created_at: pipeline.created_at,
          finished_at: pipeline.finished_at,
          duration: pipeline.duration
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
          when: build.when,
          manual: build.manual?,
          user: build.user.try(:hook_attrs),
          runner: build.runner && runner_hook_attrs(build.runner),
          artifacts_file: {
            filename: build.artifacts_file.filename,
            size: build.artifacts_size
          }
        }
      end

      def runner_hook_attrs(runner)
        {
          id: runner.id,
          description: runner.description,
          active: runner.active?,
          is_shared: runner.is_shared?
        }
      end
    end
  end
end
