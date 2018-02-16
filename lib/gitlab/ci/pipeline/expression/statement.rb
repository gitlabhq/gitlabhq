module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          def initialize(pipeline, statement)
            @pipeline = pipeline
            @statement = statement
          end

          def errors
          end

          def matches?
          end
        end
      end
    end
  end
end
