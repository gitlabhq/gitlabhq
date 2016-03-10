module Gitlab
  module Gfm
    module Ast
      module Syntax
        class Node
          attr_reader :text, :range, :parent, :nodes

          def initialize(text, range, match, parent)
            @text = text
            @range = range
            @match = match
            @parent = parent

            @value = match[:value]
            @nodes = []
          end

          ##
          # Nodes allowed inside this one.
          #
          # This is pipeline of lexemes, order is relevant.
          #
          def allowed
            raise NotImplementedError
          end

          ##
          # Method that is used to create a string representation of this node
          #
          def to_s
            raise NotImplementedError
          end

          ##
          # Returns the value of this nodes, without node-specific tokens.
          #
          def value
            raise NotImplementedError
          end

          ##
          # Process children nodes
          #
          def process!
            @nodes = lexer.new(value, allowed, self).process!
          end

          ##
          # Position of this node in parent
          #
          def index
            @range.begin
          end

          ##
          # Returns true if node is a leaf in the three.
          #
          def leaf?
            @nodes.empty?
          end

          ##
          # Each node can have it's own lexer.
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
          # Regexp pattern for this token.
          #
          def self.pattern
            raise NotImplementedError
          end
        end
      end
    end
  end
end
