# frozen_string_literal: true

# Chunk is a part of the line that starts with ` `, `-`, `+`
# Consecutive chunks build a line. Line that starts with `~` is an identifier of
# end of the line.
module Gitlab
  module WordDiff
    module Segments
      class Chunk
        def initialize(line)
          @line = line
        end

        def removed?
          line[0] == '-'
        end

        def added?
          line[0] == '+'
        end

        def to_s
          line[1..] || ''
        end

        def length
          to_s.length
        end

        private

        attr_reader :line
      end
    end
  end
end
