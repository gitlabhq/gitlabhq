# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Exists < Rules::Rule::Clause
        include Gitlab::Utils::StrongMemoize

        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        MAX_PATTERN_COMPARISONS = 50_000

        WILDCARD_NESTED_PATTERN = "**/*"

        def initialize(clause)
          @globs = Array(clause[:paths])
          @project_path = clause[:project]
          @ref = clause[:ref]
        end

        def satisfied_by?(_pipeline, context)
          # Return early to avoid redundant Gitaly calls
          return false unless @globs.any?

          context = change_context(context) if @project_path

          expanded_globs = expand_globs(context)
          top_level_only = expanded_globs.all?(&method(:top_level_glob?))

          paths = worktree_paths(context, top_level_only)
          exact_globs, extension_globs, pattern_globs = separate_globs(expanded_globs)

          exact_matches?(paths, exact_globs) ||
            matches_extension?(paths, extension_globs) ||
            pattern_matches?(paths, pattern_globs, context)
        end

        private

        def separate_globs(expanded_globs)
          grouped = expanded_globs.group_by { |glob| glob_type(glob) }
          grouped.values_at(:exact, :extension, :pattern).map { |globs| Array(globs) }
        end

        def expand_globs(context)
          @globs.map do |glob|
            expand_value_nested(glob, context)
          end
        end

        def worktree_paths(context, top_level_only)
          return [] unless context.project

          if top_level_only
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

        def pattern_matches?(paths, pattern_globs, context)
          comparisons = paths.size * pattern_globs.size

          if comparisons > MAX_PATTERN_COMPARISONS
            Gitlab::AppJsonLogger.info(
              class: self.class.name,
              message: 'rules:exists pattern comparisons limit exceeded',
              project_id: context.project&.id,
              paths_size: paths.size,
              globs_size: pattern_globs.size,
              comparisons: comparisons
            )
            return true
          end

          pattern_globs.any? do |glob|
            Gitlab::SafeRequestStore.fetch("ci_rules_exists_pattern_matches_#{context.project&.id}_#{glob}") do
              paths.any? do |path|
                pattern_match?(glob, path)
              end
            end
          end
        end

        def pattern_match?(glob, path)
          File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
        end

        # matches glob patterns that only match files in the top level directory
        def top_level_glob?(glob)
          glob.exclude?('/') && glob.exclude?('**')
        end

        # matches glob patterns that have no metacharacters for File#fnmatch?
        def exact_glob?(glob)
          glob.exclude?('*') && glob.exclude?('?') && glob.exclude?('[') && glob.exclude?('{')
        end

        # matches glob patterns like **/*.js or **/*.so.1 to optimize with path.end_with?('.js')
        def extension_glob?(glob)
          without_nested = without_wildcard_nested_pattern(glob)

          without_nested.start_with?('.') && without_nested.exclude?('/') && exact_glob?(without_nested)
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
          full_path = expand_value_nested(@project_path, context)
          project = Project.find_by_full_path(full_path)

          unless project && Ability.allowed?(user, :read_code, project)
            raise Rules::Rule::Clause::ParseError,
              "rules:exists:project `#{mask_context_variables_from(context, full_path)}` not found or access denied"
          end

          project
        end

        def find_context_sha(project, context)
          return project.commit&.sha unless @ref

          ref = expand_value_nested(@ref, context)
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

        def expand_value_nested(value, context)
          ExpandVariables.expand_existing(value, -> { context.variables_hash_expanded })
        end
      end
    end
  end
end
