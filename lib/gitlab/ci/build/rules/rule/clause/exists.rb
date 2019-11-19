# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Exists < Rules::Rule::Clause
        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        MAX_PATTERN_COMPARISONS = 10_000

        def initialize(globs)
          globs = Array(globs)

          @top_level_only = globs.all?(&method(:top_level_glob?))
          @exact_globs, @pattern_globs = globs.partition(&method(:exact_glob?))
        end

        def satisfied_by?(pipeline, context)
          paths = worktree_paths(pipeline)

          exact_matches?(paths) || pattern_matches?(paths)
        end

        private

        def worktree_paths(pipeline)
          if @top_level_only
            pipeline.top_level_worktree_paths
          else
            pipeline.all_worktree_paths
          end
        end

        def exact_matches?(paths)
          @exact_globs.any? { |glob| paths.bsearch { |path| glob <=> path } }
        end

        def pattern_matches?(paths)
          comparisons = 0
          @pattern_globs.any? do |glob|
            paths.any? do |path|
              comparisons += 1
              comparisons > MAX_PATTERN_COMPARISONS || pattern_match?(glob, path)
            end
          end
        end

        def pattern_match?(glob, path)
          File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
        end

        # matches glob patterns that only match files in the top level directory
        def top_level_glob?(glob)
          !glob.include?('/') && !glob.include?('**')
        end

        # matches glob patterns that have no metacharacters for File#fnmatch?
        def exact_glob?(glob)
          !glob.include?('*') && !glob.include?('?') && !glob.include?('[') && !glob.include?('{')
        end
      end
    end
  end
end
