module Gitlab
  module Gfm
    module Ast
      class Lexer
        class LexerError < StandardError; end

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
          process_nodes!
          @nodes.each(&:process!)
          @nodes.sort!
        end

        private

        ##
        # Processes lexeme nodes for each token in this lexer.
        #
        def process_nodes!
          return if @tokens.empty?

          @tokens.each do |token|
            ranges_available.each do |range|
              process_range!(range, token)
            end
          end

          unless ranges_available.empty?
            raise LexerError, 'Unprocessed nodes detected!'
          end
        end

        ##
        # Processes a given range.
        #
        # If pattern is found in a range, but this range is already covered
        # by an existing node, we ommit this one (flat search).
        #
        def process_range!(range, token)
          (@text[range]).scan(token.pattern).each do
            match, offset = Regexp.last_match, range.begin
            range = (match.begin(0) + offset)...(match.end(0) + offset)

            next if ranges_taken.any? { |taken| taken.include?(range.begin) }

            @nodes << token.new(match[0], range, match, @parent)
          end
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

          text_indexes = (0..(@text.length - 1)).to_a
          indexes_available = (text_indexes - indexes_taken).sort.uniq

          indexes_available.inject([]) do |ranges, n|
            if ranges.empty? || ranges.last.last != n - 1
              ranges + [n..n]
            else
              ranges[0..-2] + [ranges.last.first..n]
            end
          end
        end

        ##
        # Processes single token, and returns first lexeme that has been
        # created.
        #
        def self.single(text, token)
          lexer = new(text, [token])
          nodes = lexer.process!
          nodes.first
        end
      end
    end
  end
end
