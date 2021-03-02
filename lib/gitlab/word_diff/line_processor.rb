# frozen_string_literal: true

# Converts a line from `git diff --word-diff=porcelain` output into a segment
#
# Possible options:
# 1. Diff hunk
# 2. Chunk
# 3. Newline
module Gitlab
  module WordDiff
    class LineProcessor
      def initialize(line)
        @line = line
      end

      def extract
        return if empty_line?
        return Segments::DiffHunk.new(full_line) if diff_hunk?
        return Segments::Newline.new if newline_delimiter?

        Segments::Chunk.new(full_line)
      end

      private

      attr_reader :line

      def diff_hunk?
        line =~ /^@@ -/
      end

      def empty_line?
        full_line == ' '
      end

      def newline_delimiter?
        full_line == '~'
      end

      def full_line
        @full_line ||= line.delete("\n")
      end
    end
  end
end
