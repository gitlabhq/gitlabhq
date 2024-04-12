# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Exists < Rules::Rule::Clause
        include Gitlab::Utils::StrongMemoize

        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        MAX_PATTERN_COMPARISONS = 10_000

        WILDCARD_NESTED_PATTERN = "**/*"

        def initialize(clause)
          # Remove this variable when FF `ci_support_rules_exists_paths_and_project` is removed
          @clause = clause

          if complex_exists_enabled?
            @globs = Array(clause[:paths])
            @project_path = clause[:project]
            @ref = clause[:ref]
          else
            @globs = Array(clause)
          end

          @top_level_only = @globs.all?(&method(:top_level_glob?))
        end

        def satisfied_by?(_pipeline, context)
          if complex_exists_enabled? && @project_path
            # Return early to avoid redundant Gitaly calls
            return false unless @globs.any?

            context = change_context(context)
          end

          paths = worktree_paths(context)
          exact_globs, extension_globs, pattern_globs = separate_globs(context)

          exact_matches?(paths, exact_globs) ||
            matches_extension?(paths, extension_globs) ||
            pattern_matches?(paths, pattern_globs)
        end

        private

        def separate_globs(context)
          expanded_globs = expand_globs(context)

          grouped = expanded_globs.group_by { |glob| glob_type(glob) }
          grouped.values_at(:exact, :extension, :pattern).map { |globs| Array(globs) }
        end

        def expand_globs(context)
          @globs.map do |glob|
            # TODO: Replace w/ `expand_value(glob, context)` when FF `ci_support_rules_exists_paths_and_project` removed
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

        def change_context(old_context)
          user = find_context_user(old_context)
          new_project = find_context_project(user, old_context)
          new_sha = find_context_sha(new_project, old_context)

          Gitlab::Ci::Config::External::Context.new(
            project: new_project,
            user: user,
            sha: new_sha,
            variables: old_context.variables
          )
        end

        def find_context_user(context)
          context.is_a?(Gitlab::Ci::Config::External::Context) ? context.user : context.pipeline.user
        end

        def find_context_project(user, context)
          full_path = expand_value(@project_path, context)
          project = Project.find_by_full_path(full_path)

          unless project
            raise Rules::Rule::Clause::ParseError,
              "rules:exists:project `#{mask_context_variables_from(context, full_path)}` is not a valid project path"
          end

          unless Ability.allowed?(user, :read_code, project)
            raise Rules::Rule::Clause::ParseError,
              "rules:exists:project access denied to project " \
              "`#{mask_context_variables_from(context, project.full_path)}`"
          end

          project
        end

        def find_context_sha(project, context)
          return project.commit&.sha unless @ref

          ref = expand_value(@ref, context)
          commit = project.commit(ref)

          unless commit
            raise Rules::Rule::Clause::ParseError,
              "rules:exists:ref `#{mask_context_variables_from(context, ref)}` is not a valid ref " \
              "in project `#{mask_context_variables_from(context, project.full_path)}`"
          end

          commit.sha
        end

        def mask_context_variables_from(context, string)
          context.variables.reduce(string.dup) do |str, variable|
            if variable[:masked]
              Gitlab::Ci::MaskSecret.mask!(str, variable[:value])
            else
              str
            end
          end
        end

        def expand_value(value, context)
          ExpandVariables.expand_existing(value, -> { context.variables_hash })
        end

        def complex_exists_enabled?
          # We do not need to check the FF `ci_support_rules_exists_paths_and_project` here.
          # Instead, we can simply check if the value is a Hash because it can only be a Hash
          # if the FF was on when `Entry::Rules::Rule::Exists` was composed. The entry is
          # always composed before we reach this point. This also ensures we have the correct
          # value type before processing, which is safer.
          @clause.is_a?(Hash)
        end
      end
    end
  end
end
