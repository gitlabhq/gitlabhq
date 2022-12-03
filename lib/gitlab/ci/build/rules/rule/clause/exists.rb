# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Exists < Rules::Rule::Clause
        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        MAX_PATTERN_COMPARISONS = 10_000

        def initialize(globs)
          @globs = Array(globs)
          @top_level_only = @globs.all?(&method(:top_level_glob?))
        end

        def satisfied_by?(_pipeline, context)
          paths = worktree_paths(context)
          exact_globs, pattern_globs = separate_globs(context)

          exact_matches?(paths, exact_globs) || pattern_matches?(paths, pattern_globs)
        end

        private

        def separate_globs(context)
          expanded_globs = expand_globs(context)
          expanded_globs.partition(&method(:exact_glob?))
        end

        def expand_globs(context)
          @globs.map do |glob|
            ExpandVariables.expand_existing(glob, -> { context.variables_hash })
          end
        end

        def worktree_paths(context)
          return [] unless context.project

          if @top_level_only
            context.top_level_worktree_paths
          else
            context.all_worktree_paths
          end
        end

        def exact_matches?(paths, exact_globs)
          exact_globs.any? do |glob|
            paths.bsearch { |path| glob <=> path }
          end
        end

        def pattern_matches?(paths, pattern_globs)
          comparisons = 0

          pattern_globs.any? do |glob|
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
