# frozen_string_literal: true

module Gitlab
  module Ci
    module Pipeline
      module Expression
        module Lexeme
          class Pattern
            require_dependency 're2'
            class RegularExpression
              include Gitlab::Utils::StrongMemoize

              attr_reader :value

              def initialize(value)
                @value = value
              end

              def expression
                Gitlab::SafeRequestStore.fetch("#{self.class}#unsafe_regexp:#{value}") do
                  Gitlab::UntrustedRegexp::RubySyntax.fabricate!(value)
                end
              end
              strong_memoize_attr :expression

              def valid?
                !!expression
              rescue RegexpError
                false
              end
            end
          end
        end
      end
    end
  end
end
