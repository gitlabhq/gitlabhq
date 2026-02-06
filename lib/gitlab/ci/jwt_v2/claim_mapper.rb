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
          @mapper = mapper_class&.new(project_config, pipeline)
        end

        def to_h
          return @mapper.to_h if @mapper

          # nil `ci_config_ref_uri` causes Fulcio to crash.
          if @pipeline && Feature.enabled?(:default_jwt_ci_config_ref_uri, @pipeline.project)
            return {
              ci_config_ref_uri: ci_config_ref_uri,
              ci_config_sha: @pipeline.sha
            }
          end

          {}
        end

        private

        def ci_config_ref_uri
          project = @pipeline.project
          default_url = File.join(Settings.build_server_fqdn, project.full_path, '//',
            project.ci_config_path_or_default)

          "#{default_url}@#{@pipeline.source_ref_path}"
        end
      end
    end
  end
end
