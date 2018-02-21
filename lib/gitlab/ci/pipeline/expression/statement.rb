module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          GRAMMAR = [
            %w[variable equals string],
            %w[variable equals variable],
            %w[variable equals null],
            %w[string equals variable],
            %w[null equals variable],
            %w[variable]
          ]

          def initialize(pipeline, statement)
            @pipeline = pipeline
            @statement = statement
          end

          def variables
          end

          def evaluate
          end
        end
      end
    end
  end
end
