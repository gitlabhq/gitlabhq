# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Policy
        class Refs < Policy::Specification
          def initialize(refs)
            @patterns = Array(refs)
          end

          def satisfied_by?(pipeline, context = nil)
            @patterns.any? do |pattern|
              pattern, path = pattern.split('@', 2)

              matches_path?(path, pipeline) &&
                matches_pattern?(pattern, pipeline)
            end
          end

          private

          def matches_path?(path, pipeline)
            return true unless path

            pipeline.project_full_path == path
          end

          def matches_pattern?(pattern, pipeline)
            return true if pipeline.tag? && pattern == 'tags'
            return true if pipeline.branch? && pattern == 'branches'
            return true if sanitized_source_name(pipeline) == pattern
            return true if sanitized_source_name(pipeline)&.pluralize == pattern

            # patterns can be matched only when branch or tag is used
            # the pattern matching does not work for merge requests pipelines
            if pipeline.branch? || pipeline.tag?
              if regexp = Gitlab::UntrustedRegexp::RubySyntax.fabricate(pattern, fallback: true)
                regexp.match?(pipeline.ref)
              else
                pattern == pipeline.ref
              end
            end
          end

          def sanitized_source_name(pipeline)
            @sanitized_source_name ||= pipeline&.source&.delete_suffix('_event')
          end
        end
      end
    end
  end
end
