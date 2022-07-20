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
          return true unless pipeline&.modified_paths

          expanded_globs = expand_globs(context)
          pipeline.modified_paths.any? do |path|
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
            if @globs.is_a?(Array)
              @globs
            else
              Array(@globs[:paths])
            end
          end
        end
      end
    end
  end
end
