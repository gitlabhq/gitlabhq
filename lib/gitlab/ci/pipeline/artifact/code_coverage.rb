# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Artifact
        class CodeCoverage
          include Gitlab::Utils::StrongMemoize

          def initialize(pipeline_artifact)
            @pipeline_artifact = pipeline_artifact
          end

          def for_files(filenames)
            coverage_files = raw_report["files"].select { |key| filenames.include?(key) }

            { files: coverage_files }
          end

          private

          def raw_report
            strong_memoize(:raw_report) do
              @pipeline_artifact.each_blob do |blob|
                Gitlab::Json.parse(blob)
              end
            end
          end
        end
      end
    end
  end
end
