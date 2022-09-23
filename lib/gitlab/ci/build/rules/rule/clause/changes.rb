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
          modified_paths = find_modified_paths(pipeline)

          return true unless modified_paths

          expanded_globs = expand_globs(context)
          modified_paths.any? do |path|
            expanded_globs.any? do |glob|
              File.fnmatch?(glob, path, File::FNM_PATHNAME | File::FNM_DOTMATCH | File::FNM_EXTGLOB)
            end
          end
        end

        private

        def expand_globs(context)
          return paths unless context

          paths.map do |glob|
            ExpandVariables.expand_existing(glob, -> { context.variables_hash })
          end
        end

        def paths
          strong_memoize(:paths) do
            Array(@globs[:paths])
          end
        end

        def find_modified_paths(pipeline)
          return unless pipeline

          compare_to_sha = find_compare_to_sha(pipeline)

          if compare_to_sha
            pipeline.modified_paths_since(compare_to_sha)
          else
            pipeline.modified_paths
          end
        end

        def find_compare_to_sha(pipeline)
          return unless @globs.include?(:compare_to)

          commit = pipeline.project.commit(@globs[:compare_to])
          raise Rules::Rule::Clause::ParseError, 'rules:changes:compare_to is not a valid ref' unless commit

          commit.sha
        end
      end
    end
  end
end
