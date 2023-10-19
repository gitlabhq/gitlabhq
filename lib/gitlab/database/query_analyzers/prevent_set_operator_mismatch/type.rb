# frozen_string_literal: true

module Gitlab
  module Database
    module QueryAnalyzers
      class PreventSetOperatorMismatch
        # An enumerated set of constants that represent the state of the parse.
        module Type
          STATIC = :static
          DYNAMIC = :dynamic
          INVALID = :invalid
        end
      end
    end
  end
end
