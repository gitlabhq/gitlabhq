module Gitlab
  module Ci
    module Pipeline
      module Expression
        class Statement
          StatementError = Class.new(StandardError)

          GRAMMAR = [
            %w[variable equals string],
            %w[variable equals variable],
            %w[variable equals null],
            %w[string equals variable],
            %w[null equals variable],
            %w[variable]
          ].freeze

          def initialize(statement, pipeline = nil)
            @lexer = Expression::Lexer.new(statement)

            return if pipeline.nil?

            @variables = pipeline.runtime_variables.map do |variable|
              [variable.fetch(:key), variable.fetch(:value)]
            end
          end

          def parse_tree
            raise StatementError if @lexer.lexemes.empty?

            unless GRAMMAR.find { |syntax| syntax == @lexer.lexemes }
              raise StatementError, 'Unknown pipeline expression!'
            end

            Expression::Parser.new(@lexer.tokens).tree
          end

          def evaluate
            parse_tree.evaluate(@variables.to_h)
          end

          def inspect
            "syntax: #{@lexer.lexemes.join(' ')}"
          end

          def valid?
            parse_tree.is_a?(Lexeme::Base)
          rescue StatementError
            false
          end
        end
      end
    end
  end
end
