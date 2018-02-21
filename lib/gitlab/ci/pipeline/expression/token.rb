module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Token
          attr_reader :value, :type

          def initialize(value, type)
            @value = value
            @type = type
          end

          def to_lexeme
          end
        end
      end
    end
  end
end
