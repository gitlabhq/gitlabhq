# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Value < Lexeme::Base
            def self.type
              :value
            end

            attr_reader :value

            def initialize(value)
              @value = value
            end
          end
        end
      end
    end
  end
end
