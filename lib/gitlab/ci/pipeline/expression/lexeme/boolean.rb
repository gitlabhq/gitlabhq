# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Boolean < Lexeme::Value
            PATTERN = /\b(?:true|false)\b/

            def self.build(string)
              new(string == 'true')
            end

            def evaluate(_variables = {})
              @value
            end

            def inspect
              @value.to_s
            end
          end
        end
      end
    end
  end
end
