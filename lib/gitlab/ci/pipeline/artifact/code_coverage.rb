# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Artifact
        class CodeCoverage
          def initialize(pipeline_artifact)
            @pipeline_artifact = pipeline_artifact
          end

          def for_files(filenames)
            coverage_files = raw_report["files"].select { |key| filenames.include?(key) }

            { files: coverage_files }
          end

          private

          def raw_report
            @raw_report ||= Gitlab::Json.parse(@pipeline_artifact.file.read)
          end
        end
      end
    end
  end
end
