# frozen_string_literal: true

module Gitlab
  module Reflections
    module Relationships
      module Transformers
        # Executes a sequence of transformers in order
        class Pipeline
          def initialize(*transformers)
            @transformers = transformers
          end

          def execute(input)
            @transformers.reduce(input) { |data, t| t.call(data) }
          end
        end
      end
    end
  end
end
