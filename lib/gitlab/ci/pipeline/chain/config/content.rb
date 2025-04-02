# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content < Chain::Base
            include Chain::Helpers
            include ::Gitlab::Utils::StrongMemoize

            def perform!
              if pipeline_config&.exists?
                build_pipeline_config
                @command.config_content = pipeline_config.content
                @pipeline.config_source = pipeline_config.source
                @command.pipeline_config = pipeline_config
              else
                error('Missing CI config file')
              end
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end

            private

            def pipeline_config
              strong_memoize(:pipeline_config) do
                ::Gitlab::Ci::ProjectConfig.new(
                  project: project, sha: @pipeline.sha,
                  custom_content: @command.content,
                  pipeline_source: @command.source, pipeline_source_bridge: @command.bridge,
                  triggered_for_branch: @pipeline.branch?,
                  ref: @pipeline.ref,
                  source_branch: @command.merge_request&.source_branch || @pipeline.ref,
                  pipeline_policy_context: @command.pipeline_policy_context,
                  inputs: ::Ci::PipelineCreation::Inputs.parse_params(@command.inputs)
                )
              end
            end

            def build_pipeline_config
              # Inputs may contain secrets, so we don't want to save them in the DB as plain text.
              # It's safe to not save a pipeline-config because we are currently considering
              # dropping the `p_ci_pipelines_config` table because it's not used anywhere.
              # https://gitlab.com/gitlab-org/gitlab/-/issues/520828#note_2364398251
              return if @command.inputs.present?

              @pipeline.build_pipeline_config(content: pipeline_config.content, project_id: @pipeline.project_id)
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Config::Content.prepend_mod
