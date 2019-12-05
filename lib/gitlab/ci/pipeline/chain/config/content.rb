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
                # TODO: we should persist config_content
                # @pipeline.config_content = config.content
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
              if Feature.enabled?(:ci_root_config_content, @command.project, default_enabled: true)
                SOURCES
              else
                LEGACY_SOURCES
              end
            end
          end
        end
      end
    end
  end
end
