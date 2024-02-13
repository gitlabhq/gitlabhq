# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Exists < Rules::Rule::Clause
        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        MAX_PATTERN_COMPARISONS = 10_000

        WILDCARD_NESTED_PATTERN = "**/*"

        def initialize(globs)
          @globs = Array(globs)
          @top_level_only = @globs.all?(&method(:top_level_glob?))
        end

        def satisfied_by?(_pipeline, context)
          if ::Feature.disabled?(:ci_rule_exists_extension_optimization, context.project, type: :gitlab_com_derisk)
            return legacy_satisfied_by?(context)
          end

          paths = worktree_paths(context)
          exact_globs, extension_globs, pattern_globs = separate_globs(context)

          exact_matches?(paths, exact_globs) ||
            matches_extension?(paths, extension_globs) ||
            pattern_matches?(paths, pattern_globs)
        end

        private

        def legacy_satisfied_by?(context)
          paths = worktree_paths(context)
          exact_globs, pattern_globs = legacy_separate_globs(context)

          exact_matches?(paths, exact_globs) || pattern_matches?(paths, pattern_globs)
        end

        def legacy_separate_globs(context)
          expanded_globs = expand_globs(context)
          expanded_globs.partition(&method(:exact_glob?))
        end

        def separate_globs(context)
          expanded_globs = expand_globs(context)

          grouped = expanded_globs.group_by { |glob| glob_type(glob) }
          grouped.values_at(:exact, :extension, :pattern).map { |globs| Array(globs) }
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

        def glob_type(glob)
          if exact_glob?(glob)
            :exact
          elsif extension_glob?(glob)
            :extension
          else
            :pattern
          end
        end

        def exact_matches?(paths, exact_globs)
          exact_globs.any? do |glob|
            paths.bsearch { |path| glob <=> path }
          end
        end

        def matches_extension?(paths, extension_globs)
          return false if extension_globs.empty?

          extensions = extension_globs.map { |glob| without_wildcard_nested_pattern(glob) }

          paths.any? do |path|
            path.end_with?(*extensions)
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

        # matches glob patterns like **/*.js or **/*.so.1 to optimize with path.end_with?('.js')
        def extension_glob?(glob)
          without_nested = without_wildcard_nested_pattern(glob)

          without_nested.start_with?('.') && !without_nested.include?('/') && exact_glob?(without_nested)
        end

        def without_wildcard_nested_pattern(glob)
          glob.delete_prefix(WILDCARD_NESTED_PATTERN)
        end
      end
    end
  end
end
