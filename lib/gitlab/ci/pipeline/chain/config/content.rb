# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Chain
        module Config
          class Content < Chain::Base
            include Chain::Helpers

            SOURCES = [
              Gitlab::Ci::Pipeline::Chain::Config::Content::Parameter,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Bridge,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Repository,
              Gitlab::Ci::Pipeline::Chain::Config::Content::ExternalProject,
              Gitlab::Ci::Pipeline::Chain::Config::Content::Remote,
              Gitlab::Ci::Pipeline::Chain::Config::Content::AutoDevops
            ].freeze

            def perform!
              if config = find_config
                @pipeline.build_pipeline_config(content: config.content)
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
              SOURCES
            end
          end
        end
      end
    end
  end
end

Gitlab::Ci::Pipeline::Chain::Config::Content.prepend_mod_with('Gitlab::Ci::Pipeline::Chain::Config::Content')
