# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Seed
        class Context
          attr_reader :pipeline, :root_variables

          def initialize(pipeline, root_variables: [])
            @pipeline = pipeline
            @root_variables = root_variables
          end
        end
      end
    end
  end
end
