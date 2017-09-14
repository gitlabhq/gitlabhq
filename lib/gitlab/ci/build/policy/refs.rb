module Gitlab
  module Ci
    module Build
      module Policy
        class Refs < Policy::Specification
          def initialize(refs)
            @patterns = Array(refs)
          end

          def satisfied_by?(pipeline, path:)
            @patterns.any? do |pattern|
              pattern, ref_path = pattern.split('@', 2)

              matches_path?(ref_path, path) &&
                matches_pattern?(pattern, pipeline)
            end
          end

          private

          def matches_path?(ref_path, expected_path)
            return true unless ref_path

            expected_path == ref_path
          end

          def matches_pattern?(pattern, pipeline)
            return true if pipeline.tag? && pattern == 'tags'
            return true if pipeline.branch? && pattern == 'branches'
            return true if source_to_pattern(pipeline.source) == pattern

            if pattern.first == "/" && pattern.last == "/"
              Regexp.new(pattern[1...-1]) =~ pipeline.ref
            else
              pattern == pipeline.ref
            end
          end

          def source_to_pattern(source)
            if %w[api external web].include?(source)
              source
            else
              source&.pluralize
            end
          end
        end
      end
    end
  end
end
