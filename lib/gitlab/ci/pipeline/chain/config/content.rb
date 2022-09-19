# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content < Chain::Base
            include Chain::Helpers
            include ::Gitlab::Utils::StrongMemoize

            SOURCES = [
              Gitlab::Ci::Pipeline::Chain::Config::Content::Parameter,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Bridge,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Repository,
              Gitlab::Ci::Pipeline::Chain::Config::Content::ExternalProject,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Remote,
              Gitlab::Ci::Pipeline::Chain::Config::Content::AutoDevops
            ].freeze

            def perform!
              if pipeline_config&.exists?
                @pipeline.build_pipeline_config(content: pipeline_config.content)
                @command.config_content = pipeline_config.content
                @pipeline.config_source = pipeline_config.source
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
                next legacy_find_config if ::Feature.disabled?(:ci_project_pipeline_config_refactoring, project)

                ::Gitlab::Ci::ProjectConfig.new(
                  project: project, sha: @pipeline.sha,
                  custom_content: @command.content,
                  pipeline_source: @command.source, pipeline_source_bridge: @command.bridge
                )
              end
            end

            def legacy_find_config
              sources.each do |source|
                config = source.new(@pipeline, @command)
                return config if config.exists?
              end

              nil
            end

            def sources
              SOURCES
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Config::Content.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Config::Content')
