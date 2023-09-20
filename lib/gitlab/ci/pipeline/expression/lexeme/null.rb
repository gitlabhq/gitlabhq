# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Null < Lexeme::Value
            PATTERN = /null/

            def initialize(value = nil)
              super
            end

            def evaluate(variables = {})
              nil
            end

            def inspect
              'null'
            end

            def self.build(_value)
              self.new
            end
          end
        end
      end
    end
  end
end
