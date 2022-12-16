# frozen_string_literal: true

module Gitlab
  module Ci
    module Build
      module Context
        class Build < Base
          include Gitlab::Utils::StrongMemoize

          attr_reader :build

          def initialize(pipeline, build)
            super(pipeline)
            @build = build
          end

          def variables
            build.scoped_variables
          end
          strong_memoize_attr :variables
        end
      end
    end
  end
end
