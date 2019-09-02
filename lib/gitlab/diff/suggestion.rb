# frozen_string_literal: true

module Gitlab
  module Diff
    class Suggestion
      include Suggestible
      include Gitlab::Utils::StrongMemoize

      attr_reader :diff_file, :lines_above, :lines_below,
        :target_line

      def initialize(text, line:, above:, below:, diff_file:)
        @text = text
        @target_line = line
        @lines_above = above.to_i
        @lines_below = below.to_i
        @diff_file = diff_file
      end

      def to_hash
        {
          from_content: from_content,
          to_content: to_content,
          lines_above: @lines_above,
          lines_below: @lines_below
        }
      end

      def from_content
        strong_memoize(:from_content) do
          fetch_from_content
        end
      end

      def to_content
        return "" if @text.blank?

        # The parsed suggestion doesn't have information about the correct
        # ending characters (we may have a line break, or not), so we take
        # this information from the last line being changed (last
        # characters).
        endline_chars = line_break_chars(from_content.lines.last)
        "#{@text}#{endline_chars}"
      end

      private

      def line_break_chars(line)
        match = Gitlab::Regex.breakline_regex.match(line)
        match[0] if match
      end
    end
  end
end
