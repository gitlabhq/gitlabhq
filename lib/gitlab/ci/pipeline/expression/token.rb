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

          def build
            @type.build(@value)
          end

          def to_lexeme
            type.name.demodulize.downcase
          end
        end
      end
    end
  end
end
