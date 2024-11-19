# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        MAPPER_FOR_CONFIG_SOURCE = {
          repository_source: ClaimMapper::Repository
        }.freeze

        def initialize(project_config, pipeline)
          return unless project_config

          mapper_class = MAPPER_FOR_CONFIG_SOURCE[project_config.source]
          @mapper = mapper_class&.new(project_config, pipeline)
        end

        def to_h
          mapper.to_h
        end

        private

        attr_reader :mapper
      end
    end
  end
end
