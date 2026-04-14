# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        MAPPER_FOR_CONFIG_SOURCE = {
          repository_source: ClaimMapper::Repository,
          bridge_source: ClaimMapper::Bridge
        }.freeze

        def initialize(project_config, pipeline)
          @pipeline = pipeline

          return unless project_config

          mapper_class = MAPPER_FOR_CONFIG_SOURCE[project_config.source]
          @mapper = mapper_class&.new(pipeline)
        end

        def to_h
          return @mapper.to_h if @mapper

          # nil `ci_config_ref_uri` causes Fulcio to crash.
          if @pipeline
            return {
              ci_config_ref_uri: @pipeline.ci_config_ref_uri,
              ci_config_sha: @pipeline.sha
            }
          end

          {}
        end
      end
    end
  end
end
