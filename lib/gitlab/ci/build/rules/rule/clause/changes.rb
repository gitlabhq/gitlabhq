# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Changes < Rules::Rule::Clause
        include Gitlab::Utils::StrongMemoize

        # The maximum number of patterned glob comparisons that will be
        # performed before the rule assumes that it has a match
        CHANGES_MAX_PATTERN_COMPARISONS = 50_000

        def initialize(globs)
          @globs = globs
        end

        def satisfied_by?(pipeline, context)
          compare_to_sha = find_compare_to_sha(pipeline, context)
          modified_paths = find_modified_paths(pipeline, compare_to_sha)

          return true unless modified_paths
          return false if modified_paths.empty?

          expanded_globs = expand_globs(context).uniq
          return false if expanded_globs.empty?

          comparison_cache_key = comparison_key(pipeline, expanded_globs, compare_to_sha)
          changes_match?(modified_paths, expanded_globs, context, comparison_cache_key)
        end

        private

        def changes_match?(paths, globs, context, key)
          comparison_count = paths.size * globs.size
          if comparison_count > CHANGES_MAX_PATTERN_COMPARISONS
            Gitlab::AppJsonLogger.info(
              class: self.class.name,
              message: 'rules:changes pattern comparisons limit exceeded',
              project_id: context.project&.id,
              paths_size: paths.size,
              globs_size: globs.size,
              comparisons: comparison_count
            )
            return true
          end

          Gitlab::SafeRequestStore.fetch(key) do
            match?(globs, paths)
          end
        end

        def comparison_key(pipeline, globs, comparison_sha)
          [
            self.class.to_s,
            '#satisfied_by?',
            pipeline.project_id,
            pipeline.sha,
            comparison_sha,
            globs.sort
          ]
        end

        def match?(globs, paths)
          paths.any? do |path|
            globs.any? do |glob|
              File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
            end
          end
        end

        def expand_globs(context)
          return paths unless context

          paths.map do |glob|
            expand_value_nested(glob, context)
          end
        end

        def paths
          strong_memoize(:paths) do
            Array(@globs[:paths]).uniq
          end
        end

        def find_modified_paths(pipeline, compare_to_sha)
          return unless pipeline

          if compare_to_sha
            pipeline.modified_paths_since(compare_to_sha)
          else
            pipeline.changed_paths&.map(&:path)
          end
        end

        def find_compare_to_sha(pipeline, context)
          return unless @globs.include?(:compare_to)

          compare_to = expand_value_nested(@globs[:compare_to], context)
          commit = pipeline.project.commit(compare_to)
          raise Rules::Rule::Clause::ParseError, 'rules:changes:compare_to is not a valid ref' unless commit

          commit.sha
        end

        def expand_value_nested(value, context)
          ExpandVariables.expand_existing(value, -> { context.variables_hash_expanded })
        end
      end
    end
  end
end
