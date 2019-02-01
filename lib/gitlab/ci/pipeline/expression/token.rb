# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Token
          attr_reader :value, :lexeme

          def initialize(value, lexeme)
            @value = value
            @lexeme = lexeme
          end

          def build(*args)
            @lexeme.build(@value, *args)
          end

          def type
            @lexeme.type
          end

          def to_lexeme
            @lexeme.name.demodulize.downcase
          end
        end
      end
    end
  end
end
