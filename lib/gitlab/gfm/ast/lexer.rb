module Gitlab
  module Gfm
    module Ast
      class Lexer
        ##
        # GFM AST Lexer
        #
        def initialize(text, tokens, parent = nil)
          @text = text
          @tokens = tokens
          @parent = parent
          @nodes = []
        end

        ##
        # Returns all nodes that has been found in text.
        #
        # We expect that all text is covered by lexemes.
        #
        def process!
          @tokens.each do |token|
            ranges_available.each do |range|
              process_range(token, range)
            end
          end

          validate!
          @nodes.each(&:process!)
          @nodes.sort!
        end

        private

        ##
        # Processes a given range.
        #
        # If pattern is found in a range, but this range is already covered
        # by an existing node, we ommit this one (flat search).
        #
        def process_range(token, range)
          (@text[range]).scan(token.pattern).each do
            match = Regexp.last_match
            next if ranges_taken.any? { |taken| taken.include?(match.begin(0)) }

            @nodes << lexeme(token, match)
          end
        end

        def lexeme(token, match)
          text, range = match[0], (match.begin(0)..(match.end(0)))
          token.new(text, range, match, @parent)
        end

        def validate!
        end

        def ranges_taken
          @nodes.map(&:range)
        end

        ##
        # TODO, ugly method we have to use until we have Range#- operator
        #
        def ranges_available
          indexes_taken = @nodes.each_with_object([]) do |node, taken|
            taken.concat(node.range.to_a)
          end

          text_indexes = (0..@text.length).to_a
          indexes_available = (text_indexes - indexes_taken).sort.uniq
          indexes_available.inject([]) do |ranges, n|
            if ranges.empty? || ranges.last.last != n - 1
              ranges + [n..n]
            else
              ranges[0..-2] + [ranges.last.first..n]
            end
          end
        end
      end
    end
  end
end
