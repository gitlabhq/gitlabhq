# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Changes < Rules::Rule::Clause
        include Gitlab::Utils::StrongMemoize

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

          cache_key = [
            self.class.to_s,
            '#satisfied_by?',
            pipeline.project_id,
            pipeline.sha,
            compare_to_sha,
            expanded_globs.sort
          ]
          Gitlab::SafeRequestStore.fetch(cache_key) do
            match?(expanded_globs, modified_paths)
          end
        end

        private

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
            pipeline.modified_paths
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
