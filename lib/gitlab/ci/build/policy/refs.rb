module Gitlab
  module Ci
    module Build
      module Policy
        class Refs < Policy::Specification
          def initialize(refs)
            @patterns = Array(refs)
          end

          def satisfied_by?(pipeline, seed = nil)
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
            return true if pipeline.source == pattern
            return true if pipeline.source&.pluralize == pattern

            if pattern.first == "/" && pattern.last == "/"
              Regexp.new(pattern[1...-1]) =~ pipeline.ref
            else
              pattern == pipeline.ref
            end
          end
        end
      end
    end
  end
end
