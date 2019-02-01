# frozen_string_literal: true

module Gitlab
  module Diff
    class InlineDiffMarkdownMarker < Gitlab::StringRangeMarker
      MARKDOWN_SYMBOLS = {
        addition: "+",
        deletion: "-"
      }.freeze

      def mark(line_inline_diffs, mode: nil)
        super(line_inline_diffs) do |text, left:, right:|
          symbol = MARKDOWN_SYMBOLS[mode]
          "{#{symbol}#{text}#{symbol}}"
        end
      end
    end
  end
end
