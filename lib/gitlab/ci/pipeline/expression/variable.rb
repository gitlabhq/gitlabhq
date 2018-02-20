module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Equality
          PATTERN = /$(?<name>\w+)/.freeze

          def initialize(value)
            @value = value
          end

          def evaluate(**variables)
          end

          def self.build(string)
          end
        end
      end
    end
  end
end
