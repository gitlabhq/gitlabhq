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
              ::Gitlab::Ci::ProjectConfig.new(**pipeline_config_params)
            end
            strong_memoize_attr :pipeline_config

            def pipeline_config_params
              {
                project: project,
                sha: @pipeline.sha,
                custom_content: @command.content,
                pipeline_source: @command.source,
                pipeline_source_bridge: @command.bridge,
                triggered_for_branch: @pipeline.branch?,
                ref: @pipeline.ref,
                source_branch: @command.merge_request&.source_branch || @pipeline.ref,
                pipeline_policy_context: @command.pipeline_policy_context,
                inputs: @command.inputs
              }
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Config::Content.prepend_mod
