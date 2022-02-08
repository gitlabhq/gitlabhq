# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      class Rules::Rule::Clause::Changes < Rules::Rule::Clause
        def initialize(globs)
          @globs = Array(globs)
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

        def expand_globs(context)
          return @globs unless context

          @globs.map do |glob|
            ExpandVariables.expand_existing(glob, -> { context.variables_hash })
          end
        end
      end
    end
  end
end
