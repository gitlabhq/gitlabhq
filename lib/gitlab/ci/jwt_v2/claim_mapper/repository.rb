# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        class Repository
          def initialize(project_config, pipeline)
            @project_config = project_config
            @pipeline = pipeline
          end

          def to_h
            {
              ci_config_ref_uri: ci_config_ref_uri,
              ci_config_sha: pipeline.sha
            }
          end

          private

          attr_reader :project_config, :pipeline

          def ci_config_ref_uri
            "#{project_config.url}@#{pipeline.source_ref_path}"
          end
        end
      end
    end
  end
end
