# frozen_string_literal: true

module Gitlab
  module Ci
    class JwtV2
      class ClaimMapper
        class Bridge
          def initialize(pipeline)
            @pipeline = pipeline
          end

          def to_h
            {
              ci_config_ref_uri: pipeline.ci_config_ref_uri,
              ci_config_sha: pipeline.sha
            }
          end

          private

          attr_reader :pipeline
        end
      end
    end
  end
end
