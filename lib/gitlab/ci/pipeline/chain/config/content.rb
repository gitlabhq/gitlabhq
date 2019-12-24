# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content < Chain::Base
            include Chain::Helpers

            SOURCES = [
              Gitlab::Ci::Pipeline::Chain::Config::Content::Runtime,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Repository,
              Gitlab::Ci::Pipeline::Chain::Config::Content::ExternalProject,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Remote,
              Gitlab::Ci::Pipeline::Chain::Config::Content::AutoDevops
            ].freeze

            LEGACY_SOURCES = [
              Gitlab::Ci::Pipeline::Chain::Config::Content::Runtime,
              Gitlab::Ci::Pipeline::Chain::Config::Content::LegacyRepository,
              Gitlab::Ci::Pipeline::Chain::Config::Content::LegacyAutoDevops
            ].freeze

            def perform!
              if config = find_config
                @pipeline.build_pipeline_config(content: config.content) if ci_root_config_content_enabled?
                @command.config_content = config.content
                @pipeline.config_source = config.source
              else
                error('Missing CI config file')
              end
            end

            def break?
              @pipeline.errors.any? || @pipeline.persisted?
            end

            private

            def find_config
              sources.each do |source|
                config = source.new(@pipeline, @command)
                return config if config.exists?
              end

              nil
            end

            def sources
              ci_root_config_content_enabled? ? SOURCES : LEGACY_SOURCES
            end

            def ci_root_config_content_enabled?
              Feature.enabled?(:ci_root_config_content, @command.project, default_enabled: true)
            end
          end
        end
      end
    end
  end
end
