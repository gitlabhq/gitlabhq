module Gitlab
  module Gfm
    module Ast
      module Syntax
        class Node
          attr_reader :text, :range, :parent, :value, :nodes

          def initialize(text, range, match, parent)
            @text = text
            @range = range
            @match = match
            @parent = parent

            @value = match[:value]
            @nodes = []
          end

          ##
          # Process children nodes
          #
          def process!
            @nodes = lexer.new(@text, self.class.allowed, self).process!
          end

          def index
            @range.begin
          end

          ##
          # Method that is used to create a string representation of this node
          #
          def to_s
            @text
          end

          ##
          # Is this node a leaf node?
          #
          def leaf?
            @nodes.empty?
          end

          ##
          # Lexer for this node
          #
          def lexer
            Ast::Lexer
          end

          def <=>(other)
            return unless other.kind_of?(Node)

            case
            when index < other.index then -1
            when index == other.index then 0
            when index > other.index then 1
            end
          end

          ##
          # Better inspect
          #
          def inspect
            "#{self.class.name} #{@range}: #{@nodes.inspect}"
          end

          ##
          # Nodes allowed inside this one.
          #
          # This is pipeline of lexemes, order is relevant.
          #
          def self.allowed
            raise NotImplementedError
          end

          ##
          # Regexp pattern for this node
          #
          # Each pattern must contain at least `value` capture group.
          #
          def self.pattern
            raise NotImplementedError
          end
        end
      end
    end
  end
end
